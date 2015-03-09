#===============================================================================
# Huxley - Command-Line Interface for the Awesome Deployment Framework, Huxley.
#===============================================================================
# This file specifies the Command-Line Interface for Huxley.  Huxley keeps track
# of configuration data, so by entering short and simple commands into the
# command-line, you can manage complex deployments.  This CLI interfaces with
# the Huxley API, a wrapper around a number of open-source deployment components.
#===============================================================================
# Modules
#===============================================================================
# Core Libraries
fs = require "fs"
{resolve, join} = require "path"

# Panda Strike Libraries
Configurator = require "panda-config"           # data file parsing
{parse} = require "c50n"                        # CSON parsing (temp)
{read, shuffle, shell, merge, partial,
 map, pluck} =
                    require "fairmont"          # utility functions


# Third Party Libraries
{promise} = require "when"                   #|promise library
{call} = require "when/generator"            #|-----------------
async = (require "when/generator").lift      #|-----------------
prompt = require "prompt"                    # interviewer generator
{render} = require "mustache"                # templating

# Huxley Components
api = require "./api-interface"              # interface for huxley api
config_helpers = require "./config-helpers"  # helpers for config management

templates_dir_relative = __dirname + "/../templates/"

#===============================================================================
# Helper Fucntions
#===============================================================================
# Just to ensure good error handling, catch any errors and bubble them up.
catch_fail = (f) ->
  try
    f()
  catch e
    throw e

# This function selects and returns a random element from an input array.
select_random = (list) ->
  list = shuffle list
  return list[0]

# Output an Info Blurb and optional message.
usage = async (entry, message) ->
  docs = yield read( resolve( __dirname, "..", "docs", entry ) )
  if message?
    throw "#{message}\n" + docs
  else
    throw docs




# Sometimes we don't care if a promise is rejected, we just need to wait for it to be done one way
# or another.  This function accepts an input promise but always resolves.
force = async (f, args...) ->
  try
    yield f args...
  catch e
    null


# In Huxley, configuration data is stored in multiple places.  This function focuses on
# two levels of configuartion.
# (1) The first is the user's home configuration, located in the huxley dotfile
#     within their $HOME directory (holds persistent data attached to their account).
# (2) The second is the application-level configuration, located in the repo's huxley
#     manifest file.  TODO: Currently, we only look in the execution path, so we require the
#     CLI  to be run in the repo's root directory.  This should use an env variable like Node and git.
pull_configuration = async () ->

  # Load the configuration from the $HOME directory.
  constructor = Configurator.make
    prefix: "."
    format: "yaml"
    paths: [ process.env.HOME ]

  home_config = constructor.make name: "huxley"
  yield home_config.load()

  # Load the application level configuration.
  constructor = Configurator.make
    extension: ".yaml"
    format: "yaml"
    paths: [ process.cwd() ]

  app_config = constructor.make name: "huxley"
  yield app_config.load()

  # Create an object that is the union of the two configurations.  Huxley observes
  # configuration scope, so application configuration will override values set in the home-configuration.
  config = merge home_config.data, app_config.data

  # Return an object we can use to make requests, but also return the panda-config instances
  # in case we need to save something.
  return {
    config: config
    home_config: home_config
    app_config: app_config
  }


#===============================================================================
# Templatizing - huxley "init" & "mixin"
#===============================================================================
# TODO: move to separate file

# removes the default settings, starts prompt
prompt_setup = ->
  prompt.message = ""
  prompt.delimiter = ""
  prompt.start()

# makes prompt yield-able
prompt_wrapper = (prompt_list) ->
  new Promise (resolve, reject) ->
    prompt.get prompt_list, (err, res) ->
      if err
        return rejecet err
      resolve res

# create directory if doesn't already exists
mkdir_idempt = (path) ->
  if !fs.existsSync path
    fs.mkdirSync path
  else
    console.log "Warning: Launch folder #{path} already exists.\nProceeding to create huxley.yaml"

# copy file
copy_file = async (from_path, from_filename, destination_path, destination_filename) ->
  fs.writeFileSync (destination_path + "/" + destination_filename + ".yaml"), ""

  from_configurator = Configurator.make
    paths: [ from_path ]
    extension: ".yaml"
  from_configuration = from_configurator.make name: from_filename
  yield from_configuration.load()
  from_config = from_configuration.data

  # edit huxley.yaml
  configurator = Configurator.make
    paths: [ destination_path ]
    extension: ".yaml"
  configuration = configurator.make name: destination_filename
  yield configuration.load()
  configuration.data = from_config
  configuration.save()



# huxley.yaml composition by copying template
# FIXME: assuming .yaml for now
append_file = async (from_path, from_filename, destination_path, destination_filename) ->
  from_configurator = Configurator.make
    paths: [ from_path ]
    extension: ".yaml"
  from_configuration = from_configurator.make name: from_filename
  yield from_configuration.load()
  from_config = from_configuration.data

  # edit huxley.yaml
  configurator = Configurator.make
    paths: [ destination_path ]
    extension: ".yaml"
  configuration = configurator.make name: destination_filename
  yield configuration.load()
  configuration.data[from_filename] = from_config
  configuration.save()

union_overwrite = async (data, file_path, file_name) ->
  from_configurator = Configurator.make
    paths: [ from_path ]
    extension: ".yaml"
  from_configuration = from_configurator.make name: from_filename
  yield from_configuration.load()
  from_config = from_configuration.data

render_template_wrapper = async ({component_name, template_filename, output_filename}) ->
  template_path = join templates_dir_relative, "#{component_name}/#{template_filename}"

  # read in the default component.yaml (to make accessable as CSON)
  configurator = Configurator.make
    paths: [ process.cwd() ]
    extension: ".yaml"
  configuration = configurator.make name: "huxley"
  yield configuration.load()

  template = yield read resolve template_path

  rendered_string = yield render template, configuration.data
  yield write join( process.cwd(), "/launch/#{component_name}/#{output_filename}"), rendered_string

# initialize mixin folders, copy over templates
init_mixin = (component_name) ->
  mkdir_idempt process.cwd() + "/launch/#{component_name}"

  append_file templates_dir_relative + "/#{component_name}", "#{component_name}", process.cwd(), "huxley"
  #union_overwrite prompt_response, process.cwd(), "huxley"
  #files = [ "Dockerfile", "#{component_name}.service", "#{component_name}.yaml" ]
  files = [ "#{component_name}.yaml" ]
  for file in files
    fs.writeFileSync process.cwd() + "/launch/#{component_name}/#{file}",
      fs.readFileSync(templates_dir_relative + "#{component_name}/#{file}")



#===============================================================================
# Sub-Command Handling
#===============================================================================
# This function prepares the "options" object to ask the API server to create a
# CoreOS cluster using your AWS credentials.
create_cluster = async (argv) ->
  # Detect if we should provide a help blurb.
  if argv[0] == "help" || argv[0] == "-h"
    yield usage "cluster_create"


  # Start by reading configuration data from the local config files.
  {config} = yield pull_configuration()

  # Did the user input a cluster name?
  if argv.length == 1
    # The user gave us a name.  Use it.
    cluster_name = argv[0]
  else
    # The user didn't give us anything.  Generate a cluster name from our list of ajectives and nouns.
    {adjectives, nouns} = parse( read( resolve( __dirname, "names.cson")))
    cluster_name = "#{select_random(adjectives)}-#{select_random(nouns)}"

  # Build "options" object for panda-cluster's create function.
  options =
    # Required
    aws: config.aws
    key_name: config.aws.key_name
    availability_zone: config.aws.availability_zone
    cluster_name: cluster_name
    public_domain: config.public_domain
    private_domain: "#{cluster_name}.cluster"

    # Optional
    channel: config.channel                   || 'stable'
    cluster_size: config.cluster_size         || 3
    instance_type: config.instance_type       || "m1.medium"
    public_keys: config.public_keys           || []
    region: config.region                     if config.region?
    formation_service_templates:
            config.extra_storage              || true
    spot_price: config.spot_price             if config.spot_price?
    virtualization: config.virtualization     || "pv"

    # Huxley Access
    url: config.huxley.url
    secret_token: config.huxley.secret_token
    email: config.huxley.email

  return options

# This function prepares the "options" object to ask the API server to delete a
# CoreOS cluster using your AWS credentials.
delete_cluster = async (argv) ->
  # Detect if we should provide a help blurb.
  if argv.length == 0 || argv[0] == "help" || argv[0] == "-h"
    yield usage "cluster_delete"

  # Start by reading configuration data from the local config files.
  {config} = yield pull_configuration()

  # Now use this raw configuration as context to build an "options" object for panda-cluster.
  options =
    # Required
    aws: config.aws
    cluster_name: cluster_name

    # Optional
    region: config.region                     if config.region?

  return options

# This function prepares the "options" object to ask the API server to poll AWS
# about the status of your cluster.
poll_cluster = async (argv) ->
  # Detect if we should provide a help blurb.
  if argv.length == 0 || argv[0] == "help" || argv[0] == "-h"
    yield usage "cluster_poll"

  # Start by reading configuration data from the local config files.
  {config} = yield pull_configuration()

  # Now use this raw configuration as context to build an "options" object for panda-cluster.
  options =
    # Required
    aws: config.aws
    cluster_name: cluster_name

    # Optional
    region: config.region                     if config.region?

  return options


# This function prepares the "options" object to ask the API server to place a githook
# on the cluster's hook server.  Then it adds to the local machine's git aliases.
add_remote = async (argv) ->
  catch_fail ->
    # Detect if we should provide a help blurb.
    if argv.length == 0 || argv[0] == "help" || argv[0] == "-h"
      yield usage "remote_add"

    # Start by reading configuration data from the local config files.
    {config, app_config} = yield pull_configuration()

    # Check to see if this remote has already been registered in the API.
    yield config_helpers.check_add_remote config, argv

    # Now use this raw configuration as context to build an "options" object for panda-hook.
    options = yield config_helpers.build_add_remote config, argv

    # With our object built, call the Huxley API.
    response = yield api.add_remote options

    # Now, add a "git remote" alias using the cluster name. The first command is allowed to fail.
    yield force shell, "git remote rm #{argv[0]}"
    yield shell "git remote add #{argv[0]} ssh://#{options.hook_address}/root/repos/#{options.repo_name}.git"

    # Save the remote ID to app-level configuration.
    yield config_helpers.update_add_remote app_config, argv, response


# Not everything we place onto the cluster needs to trigger a cascade of deployment events.
# Sometimes we just need to store data at the scope of the cluster and have it available to
# be pulled when required.  Compared to what we do with other repos on the hook server,
# these are referred to as "passive" repositories, available at git:<hook-server>:3000/passive/<repo-name>
passive_remote = async (argv) ->
  catch_fail ->
    # Detect if we should provide a help blurb.
    if argv.length == 0 || argv[0] == "help" || argv[0] == "-h"
      yield usage "remote_passive"

    # Start by reading configuration data from the local config files.
    {config} = yield pull_configuration()

    # For now, this doesn't need to be routed though the API server.  Execute a series of shell commands.
    yield run_passive_remote config, argv


# This function prepares the "options" object to ask the API server to remove a githook
# on the cluster's hook server.  Then it removes one of the local machine's git aliases.
rm_remote = async (argv) ->
  catch_fail ->
    # Detect if we should provide a help blurb.
    if argv.length == 0 || argv[0] == "help" || argv[0] == "-h"
      yield usage "remote_passive"

    # Start by reading configuration data from the local config files.
    {config, app_config} = yield pull_configuration()

    # Check to see if this remote is registered in the API.  We cannot delete what does not exist.
    yield config_helpers.check_rm_remote config, argv

    # Now use this raw configuration as context to build an "options" object for panda-hook.
    options = yield config_helpers.build_rm_remote config, argv

    # With our object built, call the Huxley API.
    response = yield api.rm_remote options

    # Remove a git remote alias using the cluster name. This command is allowed to fail.
    yield force shell, "git remote rm #{argv[0]}"

    # Remove the remote ID from the app-level configuration.
    yield config_helpers.update_rm_remote app_config, argv




#===============================================================================
# Main - Command-Line Interface
#===============================================================================
call ->
  # Chop off the argument array so that only the useful arguments remain.
  argv = process.argv[2..]

  # Deliver an info blurb if neccessary.
  if argv.length == 0 || argv[0] == "-h" || argv[0] == "help"
    yield usage "main"

  # Now, look for the specified sub-command, assemble a configuration object, and hit the API.
  prompt_setup()

  try
    switch argv[0]

      when "cluster"
        switch argv[1]
          when "create"
            options = yield create_cluster argv[2..]
            res = yield api.create_cluster options
          when "delete"
            opitions = yield delete_cluster argv[2..]
            res = yield api.delete_cluster options
          when "poll"
            options = yield poll_cluster
            res = yield api.poll_cluster options
          else
            # When the command cannot be identified, display the help guide.
            yield usage "cluster", "\nError: Command Not Found: #{argv[1]} \n"

      when "init"
        # prompt_list = [
        #   name: "project_name"
        #   description: "Application name?"
        #   default: process.cwd().split("/").pop()
        # ,
        #   name: "cluster_name"
        #   description: "Cluster name?"
        #   default: "test-cluster"
        # ]
        # res = yield prompt_wrapper prompt_list
        # {project_name} = res
        copy_file templates_dir_relative, "default-config", process.cwd(), "huxley"
        # create /launch dir
        launch_dir = process.cwd() + "/launch"
        mkdir_idempt launch_dir

      when "mixin"
        switch argv[1]

          when "node"
            # prompt_list = [
            #   name: "app_name"
            #   description: "Service name?"
            #   default: "node"
            # ,
            #   name: "start"
            #   description: "Service start?"
            #   default: "npm start"
            # ,
            #   name: "component"
            #   description: "Component name?"
            #   default: "web"
            # ]
            # res = yield prompt_wrapper prompt_list

            init_mixin "node"
            yield render_template_wrapper
              component_name: "node"
              template_filename: "node.service.template"
              output_filename: "node.service"
            yield render_template_wrapper
              component_name: "node"
              template_filename: "Dockerfile.template"
              output_filename: "Dockerfile"

          when "redis"
            # TODO: prompt for info, overwrite default
            init_mixin "redis"
          when "es" || "elasticsearch"
            # TODO: prompt for info, overwrite default
            init_mixin "elasticsearch"
          else
            # When the mixin cannot be identified, display the help guide.
            yield usage "mixin", "\nError: Unknown Mixin: #{argv[1]} \n"

      when "remote"
        switch argv[1]
          when "add"
            yield add_remote argv[2..]
          when "passive"
            yield passive_remote argv[2..]
          when "rm"
            yield rm_remote argv[2..]
          else
            # When the command cannot be identified, display the help guide.
            usage "remote", "\nError: Command Not Found: #{argv[1]} \n"


      else
        # When the command cannot be identified, display the help guide.
        yield usage "main", "\nError: Command Not Found: #{argv[0]} \n"
  catch error
    console.log "*****Apologies, there was an error: \n", error

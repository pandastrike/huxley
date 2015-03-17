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
{exists, map, merge, partial,
pluck, read, shell, sleep, write} =
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
  catch_fail ->
    if fs.existsSync join process.env.HOME, ".huxley"
      # Load the configuration from the $HOME directory.
      constructor = Configurator.make
        prefix: "."
        format: "yaml"
        paths: [ process.env.HOME ]

      home_config = constructor.make name: "huxley"
      yield home_config.load()
    else
      throw "You must establish a dotfile configuration in your $HOME directory, ~/.huxley"

    if fs.existsSync join process.cwd(), "huxley.yaml"
      # Load the application level configuration.
      constructor = Configurator.make
        extension: ".yaml"
        format: "yaml"
        paths: [ process.cwd() ]

      app_config = constructor.make name: "huxley"
      yield app_config.load()

    # Create an object that is the union of the two configurations.  Huxley observes
    # configuration scope, so application configuration will override values set in the home-configuration.
    if app_config?
      config = merge home_config.data, app_config.data
    else
      config = home_config.data

    # Return an object we can use to make requests, but also return the panda-config instances
    # in case we need to save something.
    return {
      config: config
      home_config: home_config
      app_config: app_config    if app_config?
    }


#===============================================================================
# User creation and deletion
#===============================================================================
create_user = async ({config}) ->
  {questions} = require (join __dirname, "./interviews/user-create")
  answers = yield run_interview questions
  console.log answers
  config.user_details = answers
  #yield api.create_user config

delete_user = async ({config}) ->
  {questions} = require (join __dirname, "./interviews/user-delete")
  answers = yield run_interview questions
  console.log answers
  #yield api.delete_user answers

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
        return reject err
      resolve res

# create directory if doesn't already exists
mkdir_idempt = (path) ->
  # FIXME: write separate test case check "exists"
  #console.log "****exists path: ", (yield exists path)
  #if !(yield exists path)
  if !fs.existsSync path
    fs.mkdirSync path
    true
  else
    console.log "Warning: #{path} already exists.\n"
    false

# copy file
copy_file = async (from_path, from_filename, destination_path, destination_filename) ->
  yield write (destination_path + "/" + destination_filename + ".yaml"), ""

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

# appends mixin configs to manifest
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
  #configuration.data.services[component_name] = from_config
  if configuration.data.services?
    configuration.data.services[from_filename] = from_config
  else
    configuration.data.services = {}
    configuration.data.services[from_filename] = from_config
  configuration.save()

run_interview = async (questions) ->
  res = yield prompt_wrapper questions

merge_interview_to_file = async ({answers, write_path, write_filename}) ->
  configurator = Configurator.make
    paths: [ write_path ]
    extension: ".yaml"
  configuration = configurator.make name: write_filename
  yield configuration.load()
  # merge arguments are added from left to right, meaning the right-most arg will override all previous
  configuration.data = merge configuration.data, answers
  configuration.save()

# init huxley
init = async ->
  # create /launch dir
  launch_dir = process.cwd() + "/launch"
  mkdir_idempt launch_dir
  # create default huxley.yaml
  huxley_path = join process.cwd(), "huxley.yaml"
  if fs.existsSync huxley_path
    console.log "Warning: #{huxley_path} already exists"
  else
    copy_file templates_dir_relative, "default-config", process.cwd(), "huxley"
    # begin interviews
    {questions} = require (join __dirname, "./interviews/init")
    answers = yield run_interview questions
    console.log answers
    # overwrite default with interview answers
    yield merge_interview_to_file
      answers: answers
      write_path: process.cwd()
      write_filename: "huxley"

# initialize mixin folders, copy over templates
init_mixin = async (component_name) ->
  console.log "node mixin"

  # begin interview
  {questions} = require (join __dirname, "./interviews/mixins/#{component_name}")
  answers = yield run_interview questions
  {service_name, port, start_command} = answers
  console.log answers

  # if component directory doesn't already exist
  service_dir = join process.cwd(), "/launch/#{service_name}"
  if (mkdir_idempt service_dir)
    append_file templates_dir_relative + "/#{component_name}", "#{component_name}", process.cwd(), "huxley"
    files = [
              { source: "Dockerfile.template", destination: "Dockerfile.template" },
              { source: "#{component_name}.service.template", destination: "#{service_name}.service.template" },
              { source: "#{component_name}.yaml", destination: "#{service_name}.yaml" }
            ]
    for file in files
      {source, destination} = file
      template_read_path = templates_dir_relative + "#{component_name}/#{source}"
      yield write join(service_dir, destination),
        fs.readFileSync(template_read_path)

    yield merge_interview_to_file
      answers: answers
      write_path: service_dir
      write_filename: service_name
  else
    console.log "Command failed, mixin folder #{component_name} already exists"


#===============================================================================
# Sub-Command Handling
#===============================================================================
# This function prepares the "options" object to ask the API server to create a
# CoreOS cluster using your AWS credentials.
create_cluster = async (argv) ->
  # Detect if we should provide a help blurb.

  if argv[0] == "help" || argv[0] == "-h" || argv[0] == "--help"
    yield usage "cluster_create"

  # Start by reading configuration data from the local config files.
  {config, home_config} = yield pull_configuration()

  # If no cluster name specified in argv, will attempt interview
  # Empty interview answer will use randomly generated name
  if !argv[0]
    {questions} = require (join __dirname, "./interviews/cluster-create")
    # TODO: the questions.coffee returns a function instead of an object
    {cluster_name, spot_price, public_domain} = yield run_interview questions(config)
    if cluster_name
      argv[0] = cluster_name

  # Merge interview answers into defaults
  if spot_price?
    config = merge config, {spot_price}
  if public_domain?
    config = merge config, {public_domain}

  # Check to see if this cluster has already been registered in the API.
  yield config_helpers.check_create_cluster config, argv

  # Now use this raw configuration as context to build an "options" object for panda-hook.
  options = yield config_helpers.build_create_cluster config, argv

  # With our object built, call the Huxley API.
  response = yield api.create_cluster options

  # Save the cluster ID to the root-level configuration.
  yield config_helpers.update_create_cluster home_config, options, response


# This function prepares the "options" object to ask the API server to delete a
# CoreOS cluster using your AWS credentials.
delete_cluster = async (argv) ->
  catch_fail ->
    # Detect if we should provide a help blurb.
    if argv.length == 0 || argv[0] == "help" || argv[0] == "-h" || argv[0] == "--help"
      yield usage "cluster_delete"

    # Start by reading configuration data from the local config files.
    {config, home_config} = yield pull_configuration()

    # Check to see if this cluster is registered in the API. We cannot delete what does not exist.
    yield config_helpers.check_delete_cluster config, argv

    # Now use this raw configuration as context to build an "options" object for panda-cluster.
    options = yield config_helpers.build_delete_cluster config, argv

    # With our object built, call the Huxley API.
    yield api.delete_cluster options

    # Save the deletion to the root-level configuration.
    yield config_helpers.update_delete_cluster home_config, argv


# This function prepares the "options" object to ask the API server to poll AWS
# about the status of your cluster.
poll_cluster = async (argv) ->
  # Detect if we should provide a help blurb.
  if argv.length == 0 || argv[0] == "help" || argv[0] == "-h" || argv[0] == "--help"
    yield usage "cluster_poll"

  # Start by reading configuration data from the local config files.
  {config} = yield pull_configuration()

  # Check to see if this cluster is registered in the API. We cannot delete what does not exist.
  yield config_helpers.check_poll_cluster config, argv

  # Now use this raw configuration as context to build an "options" object for panda-cluster.
  options = yield config_helpers.build_poll_cluster config, argv

  # With our object built, call the Huxley API.
  yield api.poll_cluster options



# This function prepares the "options" object to ask the API server to place a githook
# on the cluster's hook server.  Then it adds to the local machine's git aliases.
add_remote = async (argv) ->
  catch_fail ->
    # Detect if we should provide a help blurb.
    if argv.length == 0 || argv[0] == "help" || argv[0] == "-h" || argv[0] == "--help"
      yield usage "remote_add"

    # Start by reading configuration data from the local config files.
    {config, app_config} = yield pull_configuration()

    # Check to see if this remote has already been registered in the API.
    yield config_helpers.check_add_remote config, argv

    # Now use this raw configuration as context to build an "options" object for panda-hook.
    options = yield config_helpers.build_add_remote config, argv

    # With our object built, call the Huxley API.
    console.log "Installing....  One moment."
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
    if argv.length == 0 || argv[0] == "help" || argv[0] == "-h" || argv[0] == "--help"
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
    if argv.length == 0 || argv[0] == "help" || argv[0] == "-h" || argv[0] == "--help"
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
  if argv.length == 0 || argv[0] == "-h" || argv[0] == "--help" || argv[0] == "help"
    yield usage "main"

  # Now, look for the specified sub-command, assemble a configuration object, and hit the API.
  prompt_setup()

  try
    switch argv[0]

      when "user"
        switch argv[1]
          when "register"
            yield create_user config: argv[2..]
          when "delete"
            yield delete_user config: argv[2..]
          else
            # When the command cannot be identified, display the help guide.
            #yield usage "user", "\nError: Command Not Found: #{argv[1]} \n"
            console.log "Bad user command"

      when "cluster"
        switch argv[1]
          when "create"
            yield create_cluster argv[2..]
          when "delete"
            yield delete_cluster argv[2..]
          when "poll"
            yield poll_cluster argv[2..]
          else
            # When the command cannot be identified, display the help guide.
            yield usage "cluster", "\nError: Command Not Found: #{argv[1]} \n"

      when "init"
        yield init()

      when "mixin"
        switch argv[1]

          when "node"
            yield init_mixin "node"
          when "redis"
            # TODO: prompt for info, overwrite default
            yield init_mixin "redis"
          when "es" || "elasticsearch"
            # TODO: prompt for info, overwrite default
            yield init_mixin "elasticsearch"
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

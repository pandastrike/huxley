#===============================================================================
# PandaCluster - Awesome Command-Line Tool and Library to Manage CoreOS Clusters
#===============================================================================
# This file specifies the Command-Line Interface for PandaCluster.  When used as
# a command-line tool, we still call PandaCluster functions, but we have to build
# the "options" object for each method by parsing command-line arguments.
#===============================================================================
# Modules
#===============================================================================
# Core Libraries
fs = require "fs"
{resolve} = require "path"
{argv} = process

panda_config = require "panda-config"           # data file parsing
Configurator = require "panda-config"           # -----------------
{read, shuffle} = require "fairmont"            # utility functions
{parse} = require "c50n"                        # CSON parsing (temp)
fs = require "fs"

# Third Party Libraries
{extend} = require "underscore"            # functional helpers
{promise} = require "when"                 # promise libraries
{call} = require "when/generator"          # -----------------
async = (require "when/generator").lift    # -----------------
{exec} = require "shelljs"                 # command-line access
prompt = require "prompt"                  # interviewer generator

# Huxley Components
api = require "./api-interface"                 # interface for huxley api

templates_dir_relative = __dirname + "/../templates/"

#===============================================================================
# Helper Fucntions
#===============================================================================
# This function selects and returns a random element from an input array.
select_random = (list) ->
  list = shuffle list
  return list[0]


# create directory if doesn't already exists
mkdir_idempt = (path) ->
  if !fs.existsSync path
    fs.mkdirSync path
  else
    console.log "Warning: Launch folder #{path} already exists.\nProceeding to create huxley.yaml"


# ShellJS's "exec" command can run non-blocking, so we wrap it here with a promise to use with
# generators.  Future iterations will probably include error handling refinements here.
execute = (command) ->
  promise (resolve, reject) ->
    exec command, (code, output) ->
      resolve output


# copy file
# create huxley.yaml
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

# In Huxley, configuration data is stored in two places.  The first is the huxley dotfile
# in the user's $HOME directory, which holds persistent data attached to their account.
# The second is the project repo's huxley manifest file, located in our execution path.
pull_configuration = async () ->

  # Load the configuration from the $HOME directory.
  constructor = panda_config.make
    prefix: "."
    format: "yaml"
    paths: [ process.env.HOME ]

  home_config = constructor.make name: "huxley"
  yield home_config.load()

  # Load the configuration from the execution path.
  constructor = panda_config.make
    extension: ".yml"
    format: "yaml"
    paths: [ process.cwd() ]

  exec_config = constructor.make name: "huxley"
  yield exec_config.load()

  # Create an object that is the union of the two configurations.  Because the config from the executable
  # path appears second, its values will overwrite the $HOME configuration if the two objects share values.
  # TODO USE FAIRMONT
  config = extend( {}, home_config.data, exec_config.data)

  # Return an object we can use to make requests, but also return the panda-config instances
  # in case we need to save something.
  return {
    config: config
    home: home_config
    exec: exec_config
  }


#===============================================================================
# Sub-Command Handling
#===============================================================================
# This function prepares the "options" object to ask the API server to create a
# CoreOS cluster using your AWS credentials.
create_cluster = async (argv) ->
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
      config.extra_storage                    || true
    spot_price: config.spot_price             if config.spot_price?
    virtualization: config.virtualization     || "pv"

    # Huxley Access
    url: config.huxley.url
    secret_token: config.huxley.secret_token
    email: config.huxley.email

  return options



# This function prepares the "options" object to ask the API server to place a githook
# on the cluster's hook server.  Then it adds to the local machine's git aliases.
add_remote = async (argv) ->
  # Start by reading configuration data from the local config files.
  {config} = yield pull_configuration()

  # Now use this raw configuration as context to build an "options" object for panda-hook.
  options =
    cluster_address: "core@#{argv[0]}.#{config.public_domain}"
    repo_name: config.app_name
    hook_address: "root@#{argv[0]}.#{config.public_domain}:3000"
    url: config.huxley.url
    secret_token: config.huxley.secret_token
    email: config.huxley.email

  # Add a git remote alias using the cluster name. These are separated because the first
  # command is allowed to fail.
  yield execute "git remote rm  #{argv[0]}"
  yield execute "git remote add #{argv[0]} ssh://#{options.hook_address}/root/repos/#{options.repo_name}.git"

  return options

# Not everything we place onto the cluster needs to trigger a cascade of deployment events.
# Sometimes we just need to store data at the scope of the cluster and have it available to
# be pulled when required.  Compared to what we do with other repos on the hook server,
# these are referred to as "passive" repositories, available at git:<hook-server>:3000/passive/<repo-name>
passive_remote = async (argv) ->
  # Start by reading configuration data from the local config files.
  {config} = yield pull_configuration()

  # Shell to the specified cluster and create a bare repo.  Overwrite anything in our path.
  command =
    "ssh -A -o \"StrictHostKeyChecking no\"  -o \"UserKnownHostsFile=/dev/null\" " +
    "-p 3000 root@#{argv[0]}.#{config.public_domain} << EOF\n" +
    "cd /root/passive \n " +
    "if [ -d #{config.repo_name}.git ]; then \n " +
    "  rm -rf #{config.repo_name}.git \n" +
    "fi \n " +
    "mkdir #{config.repo_name}.git \n " +
    "cd #{config.repo_name}.git \n " +
    "/usr/bin/git init --bare \n " +
    "EOF"

  yield execute command

  # Next, we will add this repository to the user's git remotes.  Allow "remote rm" to fail if neccessary, so do it separately.
  yield execute "git remote rm  #{config.repo_name}"
  yield execute "git remote add #{config.repo_name} ssh://root@#{argv[0]}.#{config.public_domain}:3000/root/passive/#{config.repo_name}.git"

  # Because this does not cause a deployment, we can actually go ahead and push the
  # local repository to the passive remote. Initialize a git repo in the executable
  # path, commit everything, and push.
  command =
    "cd #{process.cwd()} &&" +
    "git init; " +
    "git add -A; "+
    "git commit -m 'Repo commited by Huxley to place on cluster.'; " +
    "git push #{config.repo_name} master"

  yield execute command


# This function prepares the "options" object to ask the API server to remove a githook
# on the cluster's hook server.  Then it removes one of the local machine's git aliases.
rm_remote = async (argv) ->
  # Start by reading configuration data from the local config files.
  {config} = yield pull_configuration()

  # Now use this raw configuration as context to build an "options" object for panda-hook.
  options =
    repo_name: config.repo_name
    hook_address: "root@#{argv[0]}.#{config.public_domain}:3000"
    url: config.huxley.url
    secret_token: config.huxley.secret_token
    email: config.huxley.email

  # Add a git remote alias using the cluster name. These are separated because the first
  # command is allowed to fail.
  yield execute "git remote rm  #{argv[0]}"

  return options
#===============================================================================
# Main - Top-Level Command-Line Interface
#===============================================================================
# Chop off the argument array so that only the useful arguments remain.
argv = argv[2..]

# Deliver an info blurb if neccessary.
if argv.length == 0 || argv[0] == "-h" || argv[0] == "help"
  usage "main"

# Now, look for the specified sub-command, assemble a configuration object, and hit the API.
call ->
  try
    switch argv[0]

      when "cluster"
        switch argv[1]
          when "create"
            options = yield create_cluster argv[2..]
            res = yield api.create_cluster options
          when "delete"
            console.log "That feature is not available."
            #res = (yield api.delete_cluster options)
          when "wait"
            console.log "That feature is not available."
            #res = (yield api.wait_on_cluster options)
          else
            # When the command cannot be identified, display the help guide.
            usage "main", "\nError: Command Not Found: #{argv[1]} \n"

      when "init"
        # TODO: prompt for info, overwrite default

        copy_file templates_dir_relative, "huxley-example", process.cwd(), "huxley"
        # create /launch dir
        launch_dir = process.cwd() + "/launch"
        mkdir_idempt launch_dir

        # create ~/.dotfile
        # FIXME: make idempotent
        app_name = "donuts"
        fs.writeFileSync (process.env.HOME + "/.#{app_name}"), ""

      when "mixin"
        switch argv[1]

          when "node"
            # TODO: prompt for info, overwrite default
            component_name = "node"
            mkdir_idempt process.cwd() + "/launch/#{component_name}"

            append_file templates_dir_relative + "/node", "#{component_name}", process.cwd(), "huxley"
            #union_overwrite prompt_response, process.cwd(), "huxley"
            files = [ "Dockerfile", "node.service", "node.yaml" ]
            for file in files
              fs.writeFileSync process.cwd() + "/launch/node/#{file}",
                fs.readFileSync(templates_dir_relative + "node/#{file}")

          when "redis"
            # TODO: prompt for info, overwrite default
            component_name = "redis"
            mkdir_idempt process.cwd() + "/launch/#{component_name}"

            append_file templates_dir_relative + "/redis", "#{component_name}", process.cwd(), "huxley"
            #union_overwrite prompt_response, process.cwd(), "huxley"
            files = [ "Dockerfile", "redis.service", "redis.yaml" ]
            for file in files
              fs.writeFileSync process.cwd() + "/launch/redis/#{file}",
                fs.readFileSync(templates_dir_relative + "redis/#{file}")
          else
            # When the command cannot be identified, display the help guide.
            usage "main", "\nError: Command Not Found: #{argv[1]} \n"

      when "remote"
        switch argv[1]
          when "add"
            options = yield add_remote argv[2..]
            res = yield api.add_remote options
          when "passive"
            yield passive_remote argv[2..]
          when "rm"
            console.log "That feature is not available."

      when "user"
        switch argv[1]
          when "create"
            console.log "That feature is not available."
            res = (yield api.create_user options)
          else
            # When the command cannot be identified, display the help guide.
            usage "main", "\nError: Command Not Found: #{argv[1]} \n"

      else
        # When the command cannot be identified, display the help guide.
        usage "main", "\nError: Command Not Found: #{argv[0]} \n"
  catch error
    throw error

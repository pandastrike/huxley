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

# Panda Strike Libraries
panda_config = require "panda-config"           # data file parsing
{read, shuffle} = require "fairmont"            # utility functions
{parse} = require "c50n"                        # CSON parsing (temp)

# Third Party Libraries
{extend} = require "underscore"                 # functional helpers
{call} = require "when/generator"               # promise libraries
async = (require "when/generator").lift
{exec} = require "shelljs"                      # command-line access
prompt = require "prompt"                       # interviewer generator

# Huxley Components
api = require "./api-interface"                 # interface for huxley api


#===============================================================================
# Helper Fucntions
#===============================================================================
# Wrap parseInt - hardcode the radix at 10 to avoid confusion
# See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/parseInt
is_integer = (value) -> parseInt(value, 10) != NaN

# Output an Info Blurb and optional message.
usage = (entry, message) ->
  if message?
    throw "#{message}\n" + read( resolve( __dirname, "../", "docs", entry ) )
  else
    throw read( resolve( __dirname, "..", "docs", entry ) )

# Accept only the allowed values for flags that take an enumerated type.
allow_only = (allowed_values, value, flag) ->
  unless value in allowed_values
    throw "\nError: Only Allowed Values May Be Specified For Flag: #{flag}\n\n"

# Accept only integers within the accepted range, inclusive.
allow_between = (min, max, value, flag) ->
  unless is_integer value
    throw "\nError: Value Must Be An Integer For Flag: #{flag}\n\n"

  unless min <= value <= max
    throw "\nError: Value Is Outside Allowed Range For Flag: #{flag}\n\n"


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

# This function selects and returns a random element from an input array.
select_random = (list) ->
  list = shuffle list
  return list[0]

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

  console.log options

  # Add a git remote alias using the cluster name. These are separated because the first
  # command is allowed to fail.
  exec "git remote rm  #{argv[0]}"
  exec "git remote add #{argv[0]} ssh://#{options.hook_address}/root/repos/#{options.repo_name}.git"

  return options


# This function prepares the "options" object to ask the API server to remove a githook
# on the cluster's hook server.  Then it removes one of the local machine's git aliases.
remote_rm = async (argv) ->
  # Start by reading configuration data from the local config files.
  {config} = yield pull_configuration()

  # Now use this raw configuration as context to build an "options" object for panda-hook.
  options =
    repo_name: config.repo_name
    hook_address: "root@#{argv[0]}.#{config.public_domain}:3000"
    url: config.huxley.url
    secret_token: config.huxley.secret_token

  # Add a git remote alias using the cluster name. These are separated because the first
  # command is allowed to fail.
  exec "git remote rm  #{argv[0]}"

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
        prompt.start()
        console.log process.cwd()
        prompt.get [ "name" ], (error, result) ->
          {name} = result
          console.log result
          #yield fs.mkdir process.env.HOME + ".#{name}"
          yield fs.writeFile process.cwd() + "/huxley.yaml"

      when "remote"
        switch argv[1]
          when "add"
            options = yield add_remote argv[2..]
            res = yield api.add_remote options
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

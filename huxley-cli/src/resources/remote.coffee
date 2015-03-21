#===============================================================================
# Huxley - Resource "remote"
#===============================================================================
# Huxley relies on git to push code to your cluster and trigger a deployment.  In
# order to tell git to target your cluster, you have to set its remote.  This file
# contains method that configure the remote setup and deletion.

{async, shell} = require "fairmont"
{usage, pull_configuration, force} = require "../helpers"
api = require "../api-interface"

{build_add_remote, check_add_remote, update_add_remote,
 build_rm_remote, check_rm_remote, update_rm_remote,
 run_passive_remote}                = require "./remote-helpers"

#---------------------
# Exposed Methods
#---------------------
module.exports =
  # This function prepares the "options" object to ask the API server to place a githook
  # on the cluster's hook server.  Then it adds to the local machine's git aliases.
  add_remote: async (argv) ->
    # Detect if we should provide a help blurb.
    if argv.length == 0 || argv[0] == "help" || argv[0] == "-h" || argv[0] == "--help"
      yield usage "remote_add"

    # Start by reading configuration data from the local config files.
    {config, app_config} = yield pull_configuration()

    # Check to see if this remote has already been registered in the API.
    yield check_add_remote config, argv

    # Now use this raw configuration as context to build an "options" object for panda-hook.
    options = yield build_add_remote config, argv

    # With our object built, call the Huxley API.
    console.log "Installing....  One moment."
    response = yield api.add_remote options

    # Now, add a "git remote" alias using the cluster name. The first command is allowed to fail.
    yield force shell, "git remote rm #{argv[0]}"
    yield shell "git remote add #{argv[0]} ssh://#{options.hook_address}/root/repos/#{options.repo_name}.git"

    # Save the remote ID to app-level configuration.
    yield update_add_remote app_config, argv, response


  # Not everything we place onto the cluster needs to trigger a cascade of deployment events.
  # Sometimes we just need to store data at the scope of the cluster and have it available to
  # be pulled when required.  Compared to what we do with other repos on the hook server,
  # these are referred to as "passive" repositories, available at git:<hook-server>:3000/passive/<repo-name>
  passive_remote: async (argv) ->
    # Detect if we should provide a help blurb.
    if argv.length == 0 || argv[0] == "help" || argv[0] == "-h" || argv[0] == "--help"
      yield usage "remote_passive"

    # Start by reading configuration data from the local config files.
    {config} = yield pull_configuration()

    # For now, this doesn't need to be routed though the API server.  Execute a series of shell commands.
    yield run_passive_remote config, argv


  # This function prepares the "options" object to ask the API server to remove a githook
  # on the cluster's hook server.  Then it removes one of the local machine's git aliases.
  rm_remote: async (argv) ->
    # Detect if we should provide a help blurb.
    if argv.length == 0 || argv[0] == "help" || argv[0] == "-h" || argv[0] == "--help"
      yield usage "remote_passive"

    # Start by reading configuration data from the local config files.
    {config, app_config} = yield pull_configuration()

    # Check to see if this remote is registered in the API.  We cannot delete what does not exist.
    yield check_rm_remote config, argv

    # Now use this raw configuration as context to build an "options" object for panda-hook.
    options = yield build_rm_remote config, argv

    # With our object built, call the Huxley API.
    response = yield api.rm_remote options

    # Remove a git remote alias using the cluster name. This command is allowed to fail.
    yield force shell, "git remote rm #{argv[0]}"

    # Remove the remote ID from the app-level configuration.
    yield update_rm_remote app_config, argv

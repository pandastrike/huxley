#===============================================================================
# Huxley - Resource "remote"
#===============================================================================
# Huxley relies on git to push code to your cluster and trigger a deployment.  In
# order to tell git to target your cluster, you have to set its remote.  This file
# contains method that configure the remote setup and deletion.

{async, shell} = require "fairmont"
{usage, pull_configuration, force} = require "../helpers"
api = (require "../api-interface").remote



#---------------------
# Exposed Methods
#---------------------
module.exports =
  # This function prepares the "options" object to ask the API server to place a githook
  # on the cluster's hook server.  Then it adds to the local machine's git aliases.
  create: async (spec) ->
    {build, check, setup} = (require "./remote-helpers").create

    # Start by reading configuration data from the local config files.
    {config} = yield pull_configuration()

    # Check to see if this remote has already been registered in the API.
    cluster = yield check config, spec

    # Now use this context to build an "options" object for panda-hook.
    options = build config, spec, cluster

    # With our object built, call the Huxley API.
    response = yield api.create options

    # Complete additional setup, here and on the hook server.
    yield setup options

    return response


  # Not everything we place onto the cluster needs to trigger a cascade of deployment events.
  # Sometimes we just need to store data at the scope of the cluster and have it available to
  # be pulled when required.  Compared to what we do with other repos on the hook server,
  # these are referred to as "passive" repositories, available at git:<hook-server>:3000/passive/<repo-name>
  passive: async (spec) ->
    {run} = (require "./remote-helpers").passive
    # Read configuration data from the local config files.
    {config} = yield pull_configuration()

    # For now, this doesn't need to be routed though the API server.  Execute a series of shell commands.
    yield run config, spec


  # This function prepares the "options" object to ask the API server to remove a githook
  # on the cluster's hook server.  Then it removes one of the local machine's git aliases.
  delete: async (spec) ->
    {build, check} = (require "./remote-helpers").delete

    # Start by reading configuration data from the local config files.
    {config} = yield pull_configuration()

    # Check to see if this remote is registered in the API.  We cannot delete what does not exist.
    cluster = yield check config, spec

    # Now use this raw configuration as context to build an "options" object for panda-hook.
    options = build config, cluster

    # With our object built, call the Huxley API.
    response = yield api.delete options

    # Remove a git remote alias using the cluster name. This command is allowed to fail.
    yield force shell, "git remote rm #{spec.first}"

    return response

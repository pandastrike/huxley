#===============================================================================
# Huxley - Resource "cluster"
#===============================================================================
# Clusters are the foundation of Huxley's deployment model.  This file contains
# functions that configure their creation and deletion.

{async, merge, collect, project} = require "fairmont"
{usage, pull_configuration} = require "../helpers"
{interview} = require "../interview"
api = (require "../api-interface").cluster

#---------------------
# Exposed Methods
#---------------------
module.exports =
  # This function prepares the "options" object to ask the API server to create a
  # CoreOS cluster using your AWS credentials.
  create: async (spec) ->
    {build} = (require "./cluster-helpers").create
    # Read configuration data from the local config files.
    {config} = yield pull_configuration()

    # Begin interview
    {questions} = require "../interviews/cluster/create.coffee"
    answers = yield interview questions config

    # Use the interview and raw configuration as context to build an "options" object for panda-hook.
    options = yield build config, spec, answers

    # With our object built, call the Huxley API.
    response = yield api.create options

    if spec.wait
      while true
        {cluster} = yield api.get options
        console.log "Waiting for cluster creation..."
        if cluster.status == "running"
          console.log "Cluster is configured and online."
          return
        yield sleep 10000
    else
      return response


  # This function prepares the "options" object to ask the API server to delete a
  # CoreOS cluster using your AWS credentials.
  delete: async (spec) ->
    {build, cleanup} = (require "./cluster-helpers").delete
    # Read configuration data from the local config files.
    {config} = yield pull_configuration()

    # Use this raw configuration as context to build an "options" object for panda-cluster.
    options = build config, spec

    # With our object built, call the Huxley API.
    response = yield api.delete options

    # Make local changes reflecting the destruction of the cluster.
    yield cleanup response

    return response.message


  describe: async (spec) ->
    {build} = (require "./cluster-helpers").describe
    # Read configuration data from the local config files.
    {config} = yield pull_configuration()

    # Use this raw configuration as context to build an "options" object for panda-cluster.
    options = build config, spec

    # With our object built, call the Huxley API.
    response = yield api.get options

    message = ""
    message += "#{k}: #{v.toString()}\n" for k, v of response.cluster
    return message


  list: async (spec) ->
    {build} = (require "./cluster-helpers").list
    # Read configuration data from the local config files.
    {config, home_config} = yield pull_configuration()

    # Use this raw configuration as context to build an "options" object for panda-cluster.
    options = build config

    # With our object built, call the Huxley API.
    response = yield api.list options

    message = ""
    message += "#{name}\n" for name in collect project "name", response.clusters
    return message

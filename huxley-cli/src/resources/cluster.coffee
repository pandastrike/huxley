#===============================================================================
# Huxley - Resource "cluster"
#===============================================================================
# Clusters are the foundation of Huxley's deployment model.  This file contains
# functions that configure their creation and deletion.
{async, merge, sleep} = require "fairmont"
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
    {questions} = require "../interviews/cluster-create.coffee"
    answers = yield interview questions config
    config = merge config, answers

    # Now use the interview and raw configuration as context to build an "options" object for panda-hook.
    options = yield build config, spec

    # With our object built, call the Huxley API.
    response = yield api.create options

    if spec.wait
      while true
        {cluster} = yield api.get options
        console.log "Waiting for cluster creation..."
        if cluster.status == "running"
          console.log "Cluster is up and running"
          return
        yield sleep 10000


  # This function prepares the "options" object to ask the API server to delete a
  # CoreOS cluster using your AWS credentials.
  delete: async (spec) ->
    {build} = (require "./cluster-helpers").delete
    # Read configuration data from the local config files.
    {config} = yield pull_configuration()

    # Use this raw configuration as context to build an "options" object for panda-cluster.
    options = build config, spec

    # With our object built, call the Huxley API.
    response = yield api.delete options


  describe: async (spec) ->
    # the build helper from delete works the same for describe
    {build} = (require "./cluster-helpers").delete
    # Read configuration data from the local config files.
    {config} = yield pull_configuration()

    # Use this raw configuration as context to build an "options" object for panda-cluster.
    options = build config, spec

    # With our object built, call the Huxley API.
    response = yield api.get options
    response


  list: async (spec) ->
    {config, home_config} = yield pull_configuration()

    # the build helper from delete works the same for list
    {build} = (require "./cluster-helpers").list

    # Use this raw configuration as context to build an "options" object for panda-cluster.
    options = build config

    # With our object built, call the Huxley API.
    response = yield api.list options

    console.log "*****cluster list: ", response
    response

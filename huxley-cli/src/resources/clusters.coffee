#===============================================================================
# Huxley - Resource "clusters"
#===============================================================================
# Clusters are the foundation of Huxley's deployment model.  This file contains
# functions that configure their creation and deletion.
{async, merge} = require "fairmont"
{usage, pull_configuration} = require "../helpers"
{interview} = require "../interview"
api = (require "../api-interface").cluster

#---------------------
# Exposed Methods
#---------------------

module.exports =

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

#===============================================================================
# Huxley - Resource "cluster"
#===============================================================================
# Clusters are the foundation of Huxley's deployment model.  This file contains
# functions that configure their creation and deletion.
{async, usage} = require "fairmont"
{pull_configuration, usage} = require "../helpers"
{interview} = require "../interview"
api = require "../api-interface"

#---------------------
# Exposed Methods
#---------------------
module.exports =

  list_clusters: async (argv) ->
    # Start by reading configuration data from the local config files.
    {config, home_config} = yield pull_configuration()

    # With our object built, call the Huxley API.
    profile = yield api.get_profile {config, home_config}
    console.log profile.clusters


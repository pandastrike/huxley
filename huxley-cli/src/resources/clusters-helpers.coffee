#===============================================================================
# Huxley - Resource "clusters" - Helper Functions
#===============================================================================
# Clusters require some sophisticated configuration.  This file holds some of the
# helper functions to keep the cluster.coffee file clean.
{resolve} = require "path"
{read, async} = require "fairmont"
{parse} = require "c50n"


module.exports =

  list:

    # Construct an object that will be passed to the Huxley API to be used by its panda-cluster library.
    build: (config) ->
      return {
        huxley_url: config.huxley.url
        secret_token: config.huxley.profile.secret_token
      }

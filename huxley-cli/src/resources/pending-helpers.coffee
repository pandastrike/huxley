#===============================================================================
# Huxley - Resource "profile" - Helper Functions
#===============================================================================
# Huxley profiles require some sophisticated configuration.  This file holds
# some of the helper functions to keep the profile.coffee file clean.
{async} = require "fairmont"

module.exports =

  # Construct a configuration object to send to the Huxley API.
  build: (config, spec) ->
    return {
      huxley:
        url: config.huxley.url
        token: config.huxley.profile.token
    }

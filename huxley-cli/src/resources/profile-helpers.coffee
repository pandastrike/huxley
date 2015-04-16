#===============================================================================
# Huxley - Resource "profile" - Helper Functions
#===============================================================================
# Huxley profiles require some sophisticated configuration.  This file holds
# some of the helper functions to keep the profile.coffee file clean.

{async} = require "fairmont"

module.exports =

  create:
    # Construct a configuration object to send to the Huxley API.
    build: (config, spec) ->
      return {
        profile:
          name: spec.first || "default"
          email: spec.email || ""
        huxley:
          url: config.huxley.url
      }

    # Check the request profile against profiles the user already has on file.
    # TODO: Allow multiple profiles and move list to separate file.
    check: (config) ->
      # Throw an exception if we detect a profile.
      throw "There is already a profile in place." if config.huxley.profile


    # Upon successful profile creation by the API, save neccessary data in the huxley dotfile
    update: async (response, home_config, options) ->
      home_config.data.huxley["profile"] =
        name: options.name
        token: response.token
        email: options.email

      yield home_config.save()


  get:
    build: (config, spec) ->
      return_object = {
        huxley:
          url: config.huxley.url
        profile:
          token: config.huxley.profile.token
      }
      console.log "*****profile helpers: ", return_object
      return_object

#===============================================================================
# Huxley - Resource "profile"
#===============================================================================
# Huxley does not have "users".  We prefer to think of people as humans, humans
# with a use-case that may vary from person to person.  Therefore, the resource
# used to track these details is called "profile"

{async, merge} = require "fairmont"
{usage, pull_configuration} = require "../helpers"
api = (require "../api-interface").profile

module.exports =

  # This sub-command allows the user to establish a new Huxley profile.
  create: async (spec) ->
    {build, check, update} = (require "./profile-helpers").create

    # Pull global config from the Huxley dotfile.
    {config, home_config} = yield pull_configuration()

    # Check this request against current Huxley profiles.
    check config

    # Build a configuration object to pass to the Huxley API
    options = build config, spec

    # Access the Huxley API and create this profile.
    response = yield api.create options

    # Update the global configuration with this successful profile creation.
    yield update response, home_config, options

    return response.message



  # # This sub-command allows the user to remove a Huxley profile.
  # remove_profile: async ({argv}) ->
  #
  #
  # # This sub-command allows the user to switch to another Huxley profile.
  # use_profile: async ({argv}) ->

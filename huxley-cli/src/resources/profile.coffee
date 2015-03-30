#===============================================================================
# Huxley - Resource "profile"
#===============================================================================
# Huxley does not have "users".  We prefer to think of people as humans, humans
# with a use-case that may vary from person to person.  Therefore, the resource
# used to track these details is called "profile"

{async, merge} = require "fairmont"
{usage, pull_configuration} = require "../helpers"
api = require "../api-interface"

{build_create, check_create, parse_create, update_create} = require "./profile-helpers"


module.exports =

  # This sub-command allows the user to establish a new Huxley profile.
  create_profile: async (argv) ->
    # Parse the command-line options
    options = yield parse_create argv

    # Pull global config from the Huxley dotfile.
    {config, home_config} = yield pull_configuration()

    # Check this request against current Huxley profiles.
    check_create config, options

    # Build a configuration object to pass to the Huxley API
    request = build_create config, options

    # Access the Huxley API and create this profile.
    response = yield api.create_profile request

    # Update the global configuration with this successful profile creation.
    yield update_create response, home_config, options



  # # This sub-command allows the user to remove a Huxley profile.
  # remove_profile: async ({argv}) ->
  #
  #
  # # This sub-command allows the user to switch to another Huxley profile.
  # use_profile: async ({argv}) ->

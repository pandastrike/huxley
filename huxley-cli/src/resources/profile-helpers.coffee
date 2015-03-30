#===============================================================================
# Huxley - Resource "profile" - Helper Functions
#===============================================================================
# Huxley profiles require some sophisticated configuration.  This file holds
# some of the helper functions to keep the profile.coffee file clean.
{join} = require "path"
{async, shell, exists} = require "fairmont"
{usage, pull_configuration} = require "../helpers"

module.exports =

  # Construct a configuration object to send to the Huxley API.
  build_create: (config, options) ->
    return {
      url: config.huxley.url
      email: options.email
      profile_name: options.profile_name
    }


  # Check the request profile against profiles the user already has on file.
  # TODO: Allow multiple profiles and move list to separate file.
  check_create: (config, options) ->
    # Throw an exception if we detect a profile.
    throw "There is already a profile in place." if config.huxley.profile

  # Parses values and flags given to `huxley profile create`
  parse_create: async (argv) ->
    # Detect if we should provide a help blurb.
    if argv[0] == "help" || argv[0] == "-h" || argv[0] == "--help"
      yield usage "profile_create"

    # We will return an "options" object that collects all settings provided to this command.
    options = {}

    # Has the user specified a name for this profile?
    if argv.length != 0 && argv[0].indexOf("--") == -1
      options.profile_name = argv[0]
      argv = argv[1..]
    else
      options.profile_name = "default"

    # Parse any additional command-line flags.
    while argv.length > 0
      if argv[0].indexOf "--email=" == 0
        options.email = argv[0].split("=")[1]
      else
        usage "profile_create", "Unknown flag: #{argv[0]}"

      argv = argv[1..]

    # Enforce defaults
    options.email ||= ""

    # Return the final options object.
    return options

  # Upon successful profile creation by the API, save neccessary data in the huxley dotfile
  update_create: async (response, home_config, options) ->
    home_config.data.huxley["profile"] =
      profile_name: options.profile_name
      secret_token: response.secret_token
      email: options.email

    yield home_config.save()

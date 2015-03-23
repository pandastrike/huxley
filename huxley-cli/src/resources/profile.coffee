#===============================================================================
# Huxley - Resource "profile"
#===============================================================================
# Huxley does not have "users".  We prefer to think of people as humans, humans
# with a use-case that may vary from person to person.  Therefore, the resource
# used to track these details is called "profile"

{async} = require "fairmont"
{usage, pull_configuration} = require "../helpers"
api = require "../api-interface"


# Parses command to return the email or "default" profile
get_target_email = (argv) ->
  email = arg for arg in argv when arg.contains "--email="
  default_email = "default@gmail.com"
  profile = email?.split("=")[1] || default_email

module.exports =

  create_profile: async ({argv}) ->
    {config} = (yield pull_configuration())
    email = get_target_email argv
    # FIXME: entire config is passed in, should filter later
    yield api.create_profile {config, email}

  # TODO
  remove_profile: async ({argv}) ->
    config = yield pull_configuration()
    email = get_target_email argv
    console.log "*****removing profile: ", profile
    #yield api.delete_profile {config, profile}

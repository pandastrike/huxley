#===============================================================================
# Huxley - Resource "pending"
#===============================================================================
# Huxley executes many actions on the line, and it isn't always apparent what
# the current status is of a given action.  Pending sheds visibility on
# the current state of an actions (e.g. cluster formation).


{async} = require "fairmont"
{usage, pull_configuration, force} = require "../helpers"
api = require "../api-interface"


module.exports =

  list: async ({argv}) ->
    {config} = (yield pull_configuration())
    email = get_target_email argv
    # FIXME: entire config is passed in, should filter later
    yield api.create_profile {config, email}

  # TODO
  remove_profile: async ({argv}) ->
#    config = yield pull_configuration()
#    email = get_target_email argv
#    console.log "*****removing profile: ", profile
#    # FIXME: entire config is passed in, should filter later
#    #yield api.delete_profile {config, profile}

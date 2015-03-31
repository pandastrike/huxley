#===============================================================================
# Huxley - Resource "pending"
#===============================================================================
# Huxley executes many actions on the line, and it isn't always apparent what
# the current status is of a given action.  Pending sheds visibility on
# the current state of an actions (e.g. cluster formation).


{async} = require "fairmont"
{usage, pull_configuration} = require "../helpers"
api = require "../api-interface"


module.exports =

  list: async (argv) ->
    {config} = yield pull_configuration()
    options =
      url: config.huxley.url
      secret_token: config.huxley.profile.secret_token

    response = yield api.list_pending options
    for i in response.resources
      console.log i

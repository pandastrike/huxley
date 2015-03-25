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
    console.log "*****pending.coffee"
    # FIXME: entire config is passed in, should filter later
    yield api.list_pending {config}

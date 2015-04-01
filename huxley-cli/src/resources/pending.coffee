#===============================================================================
# Huxley - Resource "pending"
#===============================================================================
# Huxley executes many actions on the line, and it isn't always apparent what
# the current status is of a given action.  Pending sheds visibility on
# the current state of an actions (e.g. cluster formation).


{async} = require "fairmont"
{usage, pull_configuration} = require "../helpers"
api = (require "../api-interface").pending


module.exports =

  list: async (spec) ->
    {build} = (require "./pending-helpers").list
    # Read configuration data from the local config files.
    {config} = yield pull_configuration()

    # Build an options object for the Huxley API.
    options = build config, spec

    # Call the Huxley API
    response = yield api.list options
    message = ""
    for x of response.resources
      message += "#{x} \n"

    return message

  wait: async (spec) ->

#===============================================================================
# Huxley - Resource "pending"
#===============================================================================
# Huxley executes many actions on the line, and it isn't always apparent what
# the current status is of a given action.  Pending sheds visibility on
# the current state of an actions (e.g. cluster formation).


{async, sleep, empty} = require "fairmont"
{usage, pull_configuration} = require "../helpers"
{build} = require "./pending-helpers"
api = (require "../api-interface").pending

module.exports =

  list: async (spec) ->
    # Read configuration data from the local config files.
    {config} = yield pull_configuration()

    # Build an options object for the Huxley API.
    options = build config, spec

    # Call the Huxley API
    response = yield api.list options
    message = ""
    obj = response.resources
    for x of obj
      if x != "last"
        message += "Request [#{obj[x].command}] has status [#{obj[x].status}]. \n"

    return message

  wait: async (spec) ->
    # Read configuration data from the local config files.
    {config} = yield pull_configuration()

    # Build an options object for the Huxley API.
    options = build config, spec

    # Call the Huxley API
    while true
      response = yield api.list options
      if Object.keys(response.resources).length == 0
        return "Done."
      yield sleep 30000

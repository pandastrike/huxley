#===============================================================================
# Huxley - CLI Help Blurbs
#===============================================================================
# Huxley's CLI accepts actions on a variety of resources.  This file contains code
# that validates the user's request and offers command guidance when an error is detected.

{async} = require "fairmont"
{usage} = require "./helpers"

module.exports =

  # This parsing function ensures that the user selects a valid resource and matching sub-command.
  # Help blurbs are displayed whenever the user runs into trouble or requests help.
  help: async (argv) ->
    # Parse commandline arguments to identify resource, commands, and flag arguments.
    [resource, command, args...] = argv

    # Deliver the general info blurb, if neccessary.
    yield usage "main"  if !resource || resource == "-h" || resource == "--help" || resource == "help"

    # Identify the resource.
    try
      commands = require "./resources/#{resource}"
    catch error
      yield usage "main", "Error: Resource \"#{resource}\" does not exist."

    # Is the user asking for information about this resource?
    yield usage "#{resource}/main" if command == "help" || command == "-h" || command == "--help"

    # Map the allowed command names onto the ones supported by the resouces.
    command = "create" if command == "add"
    command = "delete" if command == "remove" || command == "rm" || command == "destroy"
    command = "list"   if command == "ls"

    # Validate the command.
    if resource == "init"
      command = "init"
    else
      yield usage( "#{resource}/main", "Error: Invalid command.") unless command in Object.keys(commands)

    # Is the user asking for information about this command?
    yield usage "#{resource}/#{command}" if "-h" in args || "--help" in args || "help" in args



    # It is safe for parsing to continue.  Return the command function and the remaing arguments.
    return {
      command: commands[command]
      args: args || []
    }

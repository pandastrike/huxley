#===============================================================================
# Huxley - CLI Flag Parsing
#===============================================================================
# Commands on Huxley's CLI accept configuration via flags.  This code parses
# these arguments and builds a configuration object for the CLI.  This controls
# everything from how the command is executed to how the results are displayed.

{empty} = require "./helpers"

# This function offers a way to handle, in one line, flags that require a value to be set in a follow-up argument.
require_predicate = (flag, args, options) ->
  throw "No value provided for #{flag}" if empty args
  options[flag] = args[0]
  args = args[1..]
  return {
    args: args
    options: options
  }


module.exports =
    # Parse flags in the "args" array to create a configuration object
    parse: (args) ->
      # Check if there is anything to parse.
      return {} if empty args

      # Some commands accept a single, non-flag argument as the first arugment.
      options = {}
      if args[0].indexOf("--") == -1
        options.first = args[0]
        args = args[1..]

      # The remaining flags are parsed here.
      until empty args
        flag = args.shift()
        switch flag
          when "--json" then options.json = true
          when "--yaml" then options.yaml = true
          when "--wait", "-w" then options.wait = true
          when "--email" then {args, options} = require_predicate("email", args, options)
          else
            # TODO: Add flag documentation to the help blurbs.
            throw "Error: Unsupported flag, #{flag}"

      return options

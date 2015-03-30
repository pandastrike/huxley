#===============================================================================
# Huxley - Resource "profile" - CLI Parser
#===============================================================================
# The Huxley CLI accepts input that poses a non-trival parsing problem.  The
# code to parse sub-commands of "profile" is located in this file.

{async} = require "fairmont"
{usage} = require "../helpers"
{create_profile} = require "./profile"

module.exports =

  parse_profile: async (argv) ->
    switch argv[1]
      when "create"
        yield create_profile argv[2..]
      # when "rm", "remove", "delete", "destroy"
      #   yield remove_profile argv[2..]
      # when "use"
      #   yield use_profile argv[2..]
      else
        # When the command cannot be identified, display the help guide.
        yield usage "profile", "\nError: Command Not Found: #{argv[1]} \n"

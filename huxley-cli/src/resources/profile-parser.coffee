#===============================================================================
# Huxley - Resource "profile" - CLI Parser
#===============================================================================
# The Huxley CLI accepts input that poses a non-trival parsing problem.  The
# code to parse sub-commands of "profile" is located in this file.

{async} = require "fairmont"
{usage} = require "../helpers"
{create_profile, remove_profile} = require "./profile"

module.exports =

  parse_profile: async (argv) ->
    switch argv[1]
      when "create", "add"
        # TODO
        yield create_profile {argv}
      when "rm", "remove", "delete", "destroy"
        # TODO
        yield remove_profile {argv}
      else
        # When the command cannot be identified, display the help guide.
        #yield usage "user", "\nError: Command Not Found: #{argv[1]} \n"
        console.log "*****Bad 'profile' command"

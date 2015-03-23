#===============================================================================
# Huxley - Resource "pending" - CLI Parser
#===============================================================================
# The Huxley CLI accepts input that poses a non-trival parsing problem.  The
# code to parse sub-commands of "profile" is located in this file.

{async} = require "fairmont"
{usage} = require "../helpers"
{list} = require "./pending"

module.exports =

  parse_profile: async (argv) ->
    switch argv[1]
      when "ls", "list"
        # TODO
        yield list {argv}
      else
        # When the command cannot be identified, display the help guide.
        #yield usage "user", "\nError: Command Not Found: #{argv[1]} \n"
        console.log "*****Bad 'pending' command"

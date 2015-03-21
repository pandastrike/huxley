#===============================================================================
# Huxley - Resource "cluster" - CLI Parser
#===============================================================================
# The Huxley CLI accepts input that poses a non-trival parsing problem.  The
# code to parse sub-commands of "cluster" is located in this file.

{async} = require "fairmont"
{usage} = require "../helpers"
{create_cluster, delete_cluster} = require "./cluster"

module.exports =

  parse_cluster: async (argv) ->
    switch argv[1]
      when "create"
        yield create_cluster argv[2..]
      when "delete"
        yield delete_cluster argv[2..]
      else
        # When the command cannot be identified, display the help guide.
        yield usage "cluster", "\nError: Command Not Found: #{argv[1]} \n"

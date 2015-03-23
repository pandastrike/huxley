#===============================================================================
# Huxley - Resource "cluster" - CLI Parser
#===============================================================================
# The Huxley CLI accepts input that poses a non-trival parsing problem.  The
# code to parse sub-commands of "cluster" is located in this file.

{async} = require "fairmont"
{usage} = require "../helpers"
{add_remote, rm_remote, passive_remote} = require "./remote"

module.exports =

  parse_remote: async (argv) ->
    switch argv[1]
      when "add"
        yield add_remote argv[2..]
      when "passive"
        yield passive_remote argv[2..]
      when "rm"
        yield rm_remote argv[2..]
      else
        # When the command cannot be identified, display the help guide.
        top_usage "remote", "\nError: Command Not Found: #{argv[1]} \n"

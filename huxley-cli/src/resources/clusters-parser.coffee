#===============================================================================
# Huxley - Resource "cluster" - CLI Parser
#===============================================================================
# The Huxley CLI accepts input that poses a non-trival parsing problem.  The
# code to parse sub-commands of "cluster" is located in this file.

{async} = require "fairmont"
{usage} = require "../helpers"
{list_clusters} = require "./clusters"

module.exports =

  parse_clusters: async (argv) ->
    switch argv[1]
      when "ls", "list"
        yield list_clusters argv[2..]
      else
        # When the command cannot be identified, display the help guide.
        yield usage "clusters", "\nError: Command Not Found: #{argv[1]} \n"

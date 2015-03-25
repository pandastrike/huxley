#===============================================================================
# Huxley - Resource "mixin" - CLI Parser
#===============================================================================
# The Huxley CLI accepts input that poses a non-trival parsing problem.  The
# code to parse sub-commands of "mixin" is located in this file.

{async} = require "fairmont"
{usage} = require "../helpers"
{init_mixin} = require "./mixin"

module.exports =

  parse_mixin: async (argv) ->
    switch argv[1]
      when "create", "add"
        switch argv[2]
          when "node"
            yield init_mixin "node"
          when "redis"
            # TODO: prompt for info, overwrite default
            yield init_mixin "redis"
          when "es", "elasticsearch"
            # TODO: prompt for info, overwrite default
            yield init_mixin "elasticsearch"
          else
            # When the mixin cannot be identified, display the help guide.
            yield usage "mixin", "\nError: Unknown Mixin: #{argv[1]} \n"
      when "rm", "remove", "delete", "destroy"
        switch argv[2]
          when "node"
            console.log "do nothing"
          when "redis"
            console.log "do nothing"
          when "es", "elasticsearch"
            console.log "do nothing"
          else
            # When the mixin cannot be identified, display the help guide.
            yield usage "mixin", "\nError: Unknown Mixin: #{argv[1]} \n"
      else
        # When the mixin command cannot be identified, display the help guide.
        yield usage "mixin", "\nError: Unknown Mixin Subcommand: #{argv[1]} \n"

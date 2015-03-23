#===============================================================================
# Huxley - Resource "init" - CLI Parser
#===============================================================================
# The Huxley CLI accepts input that poses a non-trival parsing problem.  The
# code to parse sub-commands of "init" is located in this file.

{async} = require "fairmont"
{init_huxley} = require "./init"

module.exports =

  parse_init: async (argv) -> yield init_huxley()

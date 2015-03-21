#===============================================================================
# Huxley - Command-Line Interface for the Awesome Deployment Framework, Huxley
#===============================================================================
# This file specifies the Command-Line Interface for Huxley.  Huxley keeps track
# of configuration data, so by entering short and simple commands into the
# command-line, you can manage complex deployments.  This CLI interfaces with
# the Huxley API, a wrapper around a number of open-source deployment components.
#===============================================================================
# Modules
#===============================================================================
# Panda Strike Libraries
{call, async} = require "fairmont"           # utility functions

# CLI Parsers
#{parse_profile} = require "./resources/profile-parser"
{parse_init} = require "./resources/init-parser"
{parse_mixin} = require "./resources/mixin-parser"
{parse_cluster} = require "./resources/cluster-parser"
{parse_remote} = require "./resources/remote-parser"

{setup_interview} = require "./interview"
{usage}  = require "./helpers"
#===============================================================================
# Main - Command-Line Interface
#===============================================================================
call ->
  # Chop off the argument array so that only the useful arguments remain.
  argv = process.argv[2..]

  # Deliver an info blurb if neccessary.
  if argv.length == 0 || argv[0] == "-h" || argv[0] == "--help" || argv[0] == "help"
    yield usage "main"

  # Prepare to ask the user questions, if neccessary.
  setup_interview()

  # Look for the specified sub-command, assemble a configuration object, and hit the API.
  try
    switch argv[0]
      when "profile"
        yield parse_profile argv
      when "cluster"
        yield parse_cluster argv
      when "init"
        yield parse_init argv
      when "mixin"
        yield parse_mixin argv
      when "remote"
        yield parse_remote argv
      else
        # When the command cannot be identified, display the help guide.
        yield usage "main", "\nError: Command Not Found: #{argv[0]} \n"
  catch error
    console.log "*****Apologies, there was an error: \n", error

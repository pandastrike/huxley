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
{call} = require "fairmont"      # utility functions

# Huxley CLI Components
{setup_interview} = require "./interview"
{help} = require "./help"
{parse} = require "./parse"
{print} = require "./print"

#===============================================================================
# Main - Command-Line Interface
#===============================================================================
call ->
  try
    # Parse the arguments array to identify command.  Offer help blurbs, if neccessary.
    {command, args} = yield help process.argv[2..]

    # Parse the sub-command arguments and build a command configuration.
    options = parse args

    # Prepare the "prompt" interviewer module.
    setup_interview()

    # Run the requested command with its configuration
    response = yield command options

    # Print out the result in the user's requested format.
    print response, options

  catch error
      console.log "Error:\n", error

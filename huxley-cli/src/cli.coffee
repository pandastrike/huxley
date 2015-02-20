#===============================================================================
# PandaCluster - Awesome Command-Line Tool and Library to Manage CoreOS Clusters
#===============================================================================
# This file specifies the Command-Line Interface for PandaCluster.  When used as
# a command-line tool, we still call PandaCluster functions, but we have to build
# the "options" object for each method by parsing command-line arguments.
#===============================================================================
# Modules
#===============================================================================
{argv} = process
{resolve} = require "path"
{read, write, remove} = require "fairmont" # Awesome utility functions.
{parse} = require "c50n"                   # Awesome .cson file parsing

{call} = require "when/generator"

# Awesome manipulations in the functional style.
{pluck, where, flatten} = require "underscore"

# Access PandaCluster!!
PC = require "./pbx"


#===============================================================================
# Helper Fucntions
#===============================================================================
# Wrap parseInt - hardcode the radix at 10 to avoid confusion
# See: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/parseInt
is_integer = (value) -> parseInt(value, 10) != NaN

# Output an Info Blurb and optional message.
usage = (entry, message) ->
  if message?
    throw "#{message}\n" + read( resolve( __dirname, "../", "docs", entry ) )
  else
    throw read( resolve( __dirname, "..", "docs", entry ) )

# Accept only the allowed values for flags that take an enumerated type.
allow_only = (allowed_values, value, flag) ->
  unless value in allowed_values
    throw "\nError: Only Allowed Values May Be Specified For Flag: #{flag}\n\n"

# Accept only integers within the accepted range, inclusive.
allow_between = (min, max, value, flag) ->
  unless is_integer value
    throw "\nError: Value Must Be An Integer For Flag: #{flag}\n\n"

  unless min <= value <= max
    throw "\nError: Value Is Outside Allowed Range For Flag: #{flag}\n\n"

# Parse the arguments passed to a sub-command.  Construct an "options" object to pass to the main library.
parse_cli = (command, argv) ->
  # Deliver an info blurb if neccessary.
  usage command   if argv[0] == "-h" || argv[0] == "help"

  # Begin constructing the "options" object by pulling persistent configuration data
  # from the CSON file in the user's $HOME directory.
  options = parse( read( resolve("#{process.env.HOME}/.pandacluster.cson")))

  # Extract flag data from the argument definition for this sub-command.
  definitions = parse( read( resolve(  __dirname, "arguments.cson")))
  cmd_def = definitions[command]  # Produces an array of objects describing this single sub-command.
  flags = pluck cmd_def, "flag"
  required_flags = pluck( where( cmd_def, {required: true}), "flag" )

  # Loop over arguments.  Collect settings into "options" and validate where possible.
  while argv.length > 0
    # Check to see if the entered flag is valid.
    if flags.indexOf(argv[0]) == -1
      usage command, "\nError: Unrecognized Flag Provided: #{argv[0]}\n"
    # Check to see if there is a "dangling" flag that has no content provided.
    if argv.length == 1
      usage command, "\nError: Valid Flag Provided But Not Defined: #{argv[0]}\n"

    # Validate the argument against its defintion.
    {name, type, required, allowed_values, min, max} = cmd_def[ flags.indexOf(argv[0]) ]

    allow_only( allowed_values, argv[1], argv[0])  if allowed_values?
    allow_between( min, max, argv[1], argv[0])     if min? and max?
    remove( required_flags, argv[0])               if required? == true

    # Add data to the "options" object.
    options[name] = argv[1]

    # Delete these two arguments.
    argv = argv[2..]

  options

  # Done looping.  Check to see if all required flags have been defined.
  unless required_flags.length == 0
    usage command, "\nError: Mandatory Flag(s) Remain Undefined: #{required_flags}\n"

  # Parsing complete. Return the completed "options" object.
  return options


#===============================================================================
# Main - Top-Level Command-Line Interface
#===============================================================================
# Chop off the argument array so that only the useful arguments remain.
argv = argv[2..]

# Deliver an info blurb if neccessary.
if argv.length == 0 || argv[0] == "-h" || argv[0] == "help"
  usage "main"

# Now, look for the specified sub-command.

call ->
  try
    switch argv[0]

      when "cluster"
        switch argv[1]
          when "create"
            options = parse_cli "create_cluster", argv[2..]
            console.log "*****cluster create args: ", options
            res = (yield PC.create_cluster options)
            console.log "*****cluster create results: ", res
          when "delete"
            options = parse_cli "delete_cluster", argv[2..]
            console.log "*****cluster delete args: ", options
            res = (yield PC.delete_cluster options)
            console.log "*****cluster delete results: ", res
          when "wait"
            options = parse_cli "wait_on_cluster", argv[2..]
            console.log "*****waiting on cluster args: ", options
            res = (yield PC.wait_on_cluster options)
            console.log "*****cluster wait results: ", res
          else
            # When the command cannot be identified, display the help guide.
            usage "main", "\nError: Command Not Found: #{argv[1]} \n"

      when "user"
        switch argv[1]
          when "create"
            options = parse_cli "create_user", argv[2..]
            console.log "*****user create args: ", options
            res = (yield PC.create_user options)
            console.log "*****user create results: ", res
          else
            # When the command cannot be identified, display the help guide.
            usage "main", "\nError: Command Not Found: #{argv[1]} \n"

      else
        # When the command cannot be identified, display the help guide.
        usage "main", "\nError: Command Not Found: #{argv[0]} \n"
  catch error
    throw error

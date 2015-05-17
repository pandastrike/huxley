# This file is where we actually run the Huxley API server.  The methods are listed
# in ./api.coffee and the actual code that makes up those methods are specified in
# ./handlers.coffee.  The library "pbx" synthesizes these specifications into a well
# behaved API server.

# Before the server starts up, we want to generate an SSH key-pair that will serve
# as a "master key" for the API server.  The public key will be placed on every
# cluster, so the API server will always have the backdoor needed to configure the
# clusters properly.  This implementation is somewhat crude, but will be refined in time.

#===============================================================================
# Modules
#===============================================================================
# Core Libraries
{createServer} = require "http"

# PandaStrike Libraries
{shell, async, call} = require "fairmont" # utility library
{processor} = require "pbx"               # API library

# Local Modules
handlers = require "./api/handlers"
spec = require "./api/spec"
keypair = require "./ssh"

# Address where the server is listening for requests.
spec.base_url = "http://localhost:8080"

#===============================================================================
# Server Spinup
#===============================================================================
call ->
  # Chop off the argument array so that only the useful arguments remain.
  argv = process.argv[2..]

  # By defualt the server generates its own SSH key.  If we place "restart" after
  # the startup command, the user can ask the server to reuse whatever keys are in place.
  yield keypair.generate()  unless argv.length != 0 && argv[0] == "restart"

  # Spinup the server.
  createServer yield (processor spec, handlers)
  .listen 8080, () -> console.log "Huxley API is online.  Listening on 8080."

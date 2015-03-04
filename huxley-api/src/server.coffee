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
http = require "http"

# PandaStrike Libraries
{processor} = require "pbx"

# Third Party Libraries
{exec} = require "shelljs"
{promise} = require "when"
{call} = require "when/generator"

# Local Modules
initialize = require "./handlers"
api = require "./api"

#===============================================================================
# Helpers
#===============================================================================
# Address where the server is listening for requests.
api.base_url = "http://localhost:8080"

# ShellJS's "exec" command can run non-blocking, so we wrap it here with a promise to use with
# generators.  Future iterations should include error handling refinements here.
execute = (command) ->
  promise (resolve, reject) ->
    exec command, (code, output) ->
      resolve output

#===============================================================================
# Server Spinup
#===============================================================================
call ->
  # Generate an SSH keypair that will serve as the API's master key.
  command = "ssh-keygen -t rsa -C 'huxley_api_master' -N '' -f huxley_master"
  yield execute command

  # Store the public key in the src directory so handlers.coffee may find it.
  command = "mv #{process.cwd()}/huxley_master.pub #{__dirname}/."
  yield execute command

  # Store the private key in the $HOME directory so it hopefully remains safe.
  command =
    "if [ -d #{process.env.HOME}/.huxley_ssh ]; then " +
      "rm -rf #{process.env.HOME}/.huxley_ssh; " +
    "fi; " +

    "mkdir #{process.env.HOME}/.huxley_ssh; " +
    "mv #{process.cwd()}/huxley_master #{process.env.HOME}/.huxley_ssh/.; " +
    "chmod 400 #{process.env.HOME}/.huxley_ssh/huxley_master"
  yield execute command

  # Add the private key to this machine's ssh-agent identity.
  command = "ssh-add #{process.env.HOME}/.huxley_ssh/huxley_master"
  yield execute command

  # Finally, spinup the server.
  http
  .createServer yield (processor api, initialize)
  .listen 8080, () -> console.log "listening on 8080"

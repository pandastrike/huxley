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
{shell} = require "fairmont"              # utility library
{processor} = require "pbx"               # API library

# Third Party Libraries
async = (require "when/generator").lift   # promise library
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

# This function allows the server to generate its own SSH keypair.  The private key
# is safely placed in the $HOME directory and the public key is made accessable
# to "handlers.coffee" so it can be put on every cluster for access.
generate_keypair = async () ->
  # Generate an SSH keypair that will serve as the API's master key.
  command = "ssh-keygen -t rsa -C 'huxley_api_master' -N '' -f huxley_master"
  {stdout} = yield shell command
  console.log stdout

  # Store the public key in the src directory so handlers.coffee may find it.
  command = "mv #{process.cwd()}/huxley_master.pub #{__dirname}/."
  yield shell command

  # Store the private key in the $HOME directory so it hopefully remains safe.
  command =
    "if [ -d #{process.env.HOME}/.huxley_ssh ]; then " +
      "rm -rf #{process.env.HOME}/.huxley_ssh; " +
    "fi; " +

    "mkdir #{process.env.HOME}/.huxley_ssh; " +
    "mv #{process.cwd()}/huxley_master #{process.env.HOME}/.huxley_ssh/.; " +
    "chmod 400 #{process.env.HOME}/.huxley_ssh/huxley_master"
  yield shell command

  # Add the private key to this machine's ssh-agent identity.
  command = "ssh-add #{process.env.HOME}/.huxley_ssh/huxley_master"
  yield shell command

#===============================================================================
# Server Spinup
#===============================================================================
call ->
  # Chop off the argument array so that only the useful arguments remain.
  argv = process.argv[2..]

  # By defualt the server generates its own SSH key.  If we place "restart" after
  # the startup command, the user can ask the server to reuse whatever keys are in place.
  yield generate_keypair()  unless argv.length != 0 && argv[0] == "restart"

  # Spinup the server.
  http
  .createServer yield (processor api, initialize)
  .listen 8080, () -> console.log "Huxley API is online.  Listening on 8080."

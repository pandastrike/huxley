#===============================================================================
# Huxley API - Server Master SSH Key
#===============================================================================
# This file contains the code neccessary to generate and store an SSH master key
# for the Huxley API server.  The server adds this key to all clusters it creates
# so that it may access and configure them.

{async, shell} = require "fairmont"

module.exports =
  # This function allows the server to generate its own SSH keypair.  The private key
  # is safely placed in the $HOME directory and the public key is made accessable
  # to "handlers.coffee" so it can be put on every cluster for access.
  generate: async () ->
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
      "mv huxley_master #{process.env.HOME}/.huxley_ssh/.; " +
      "chmod 400 #{process.env.HOME}/.huxley_ssh/huxley_master"
    yield shell command

    # Add the private key to this machine's ssh-agent identity.
    command = "ssh-add #{process.env.HOME}/.huxley_ssh/huxley_master"
    yield shell command

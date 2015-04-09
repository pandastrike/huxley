#===============================================================================
# Huxley API - Handlers - Remotes
#===============================================================================
# This file contains API handler functions for the collective resource "remotes".

{async} = require "fairmont"
{make_key} = require "./helpers"

pandahook = require "panda-hook"

module.exports = (db) ->

  # This function uses panda-hook to push a githook script onto the target cluster's hook server.
  create: async (context) ->
    {respond, data} = context
    data = yield data

    # Create a "remotes" record to be stored in the server's database.
    address = data.hook.address.split ":"
    id = make_key()
    yield db.remotes.put id,
      hook:
        address: address[0]
        port: address[1] || 22
      app:
        name: data.app.name

    # Store the remote's ID with the cluster in the API server's database.
    cluster = yield db.clusters.get data.cluster.id
    cluster.remotes.push id
    yield db.clusters.put data.cluster.id, cluster

    # Access panda-hook to create a githook and place it on the cluster.
    yield pandahook.push data
    respond 201, "githook installed", {remote_id: remote_id}

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

    # Create a record to be stored in the server's database.
    address = data.hook.address.split ":"
    record =
      hook:
        address: address[0]
        port: address[1] || 22
      app:
        name: data.app.name

    # Store the record using a unique token as the key.
    remote_id = make_key()
    db.remotes.put remote_id, record

    # Create a cluster record to be stored in the server's database.
    yield db.clusters.put data.cluster.id,
      status: "online"
      name: data.cluster.name
      public_domain: data.app.public_domain
      deployments: []
      remotes: []

    cluster = yield db.clusters.get data.cluster.id
    cluster.remotes.push remote_id
    yield db.clusters.put data.cluster.id, cluster

    # Access panda-hook to create a githook and place it on the cluster.
    yield pandahook.push data
    respond 201, "githook installed", {remote_id: remote_id}

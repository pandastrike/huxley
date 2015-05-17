#===============================================================================
# Huxley API - Handlers - Remotes
#===============================================================================
# This file contains API handler functions for the collective resource "remotes".
{async} = require "fairmont"
pandahook = require "panda-hook"

key = require "../key"

module.exports = (db) ->

  # Use panda-hook to push a githook onto the target cluster's hook server.
  create: async (context) ->
    {respond, data} = context
    data = yield data

    # Store where the hook server can be found.
    address = data.hook.address.split ":"
    id = key.generate()
    yield db.remotes.put id,
      hook:
        address: address[0]
        port: address[1] || 22
      app:
        name: data.app.name

    # Associate the above record with the cluster's record.
    cluster = yield db.clusters.get data.cluster.id
    cluster.remotes.push id
    yield db.clusters.put data.cluster.id, cluster

    # Access panda-hook to create a githook and place it on the cluster.
    try
      yield pandahook.push data
      respond 201, "githook installed", {id}
    catch error
      respond 500, error

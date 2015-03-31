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
    address = data.hook_address.split ":"
    record =
      hook_address: address[0]
      hook_port: address[1] || 22
      repo_name: data.repo_name

    # Store the record using a unique token as the key.
    remote_id = make_key()
    db.remotes.put remote_id, record

    cluster = yield db.clusters.get data.cluster_id
    cluster.remotes.push remote_id
    yield db.clusters.put data.cluster_id, cluster

    # Access panda-hook to create a githook and place it on the cluster.
    #yield pandahook.push data
    respond 201, "githook installed", {remote_id: remote_id}

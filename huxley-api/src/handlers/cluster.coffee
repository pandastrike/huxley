#===============================================================================
# Huxley API - Handlers - Cluster
#===============================================================================
# This file contains API handler functions for the single resource "cluster".

{async, remove, merge} = require "fairmont"
{get_cluster} = require "./helpers"
pandacluster = require "panda-cluster"

module.exports = (db) ->

  delete: async (context) ->
    # Parse the context for needed information.
    {request, respond, match} = context
    name = match.path.cluster_name
    token = request.headers.authorization.split(" ")[1]

    # Validate
    profile = yield db.profiles.get token
    unless profile
      respond 401
      return

    # Lookup cluster information
    cluster = yield get_cluster name, token, db, respond

    # Store this command in pending.
    command = "cluster delete #{name}"
    status = "deleting"
    db.pending.put token, command, status

    if cluster
      # Use panda-cluster to delete the cluster, and delete from database.
      options =
        aws: profile.aws
        cluster_name: name
        cluster_id: cluster.cluster_id
        command_id: "cluster delete #{name}"
        huxley:
          url: "https://#{request.headers.host}"
          token: token
      pandacluster.delete_cluster options
      respond 200, "Cluster deletion underway."
    else
      respond 404

  get: async (context) ->
    # Parse the context for needed information.
    {request, respond, match} = context
    name = match.path.cluster_name
    token = request.headers.authorization.split(" ")[1]

    if name
      cluster = yield get_cluster name, token, db, respond
    else
      respond 404

    if cluster
      # Return the database record concerning this cluster.
      respond 200, cluster
    else
      respond 404

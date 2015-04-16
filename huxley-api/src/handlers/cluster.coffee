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

    profile = yield db.profiles.get token
    unless profile
      respond 401
      return

    cluster = yield get_cluster name, token, db, respond

    if cluster
      # Use panda-cluster to delete the cluster, and delete from database.
      cluster = merge cluster, {aws: profile.aws}, {cluster_name: name}
      pandacluster.delete_cluster cluster
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

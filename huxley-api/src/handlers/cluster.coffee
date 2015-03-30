#===============================================================================
# Huxley API - Handlers - Cluster
#===============================================================================
# This file contains API handler functions for the single resource "cluster".

{async, remove} = require "fairmont"
{get_cluster, delete_cluster} = require "./helpers"
pandacluster = require "panda-cluster"

module.exports = (db) ->

  delete: async (context) ->
    # Parse the context for needed information.
    {request, respond, match} = context
    cluster_name = match.path.cluster_name
    token = request.headers.authorization.split(" ")[1]

    cluster = yield get_cluster cluster_name, token, db, respond

    if cluster
      # Use panda-cluster to delete the cluster, and delete from database.
      #pandacluster.delete_cluster cluster
      delete_cluster cluster.cluster_id, token, db
      respond 200, "Cluster deletion underway."

  get: async (context) ->
    # Parse the context for needed information.
    {request, respond, match} = context
    cluster_name = match.path.cluster_name
    token = request.headers.authorization.split(" ")[1]

    cluster = yield get_cluster cluster_name, token, db, respond

    if cluster
      # Return the database record concerning this cluster.
      respond 200, cluster

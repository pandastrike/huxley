#===============================================================================
# Huxley API - Handlers - Clusters
#===============================================================================
# This file contains API handler functions for the collective resource "clusters".

{async} = require "fairmont"
{make_key, get_master_key, get_cluster_id} = require "./helpers"
pandacluster = require "panda-cluster"

module.exports = (db) ->

  create: async (context) ->
    # Parse the context for needed information.
    {respond, data} = context
    data = yield data

    # Validation.  Make sure the profile exists and the cluster name is not already in use.
    if (!data.secret_token) || !(yield db.profiles.get data.secret_token)
      respond 401, "Unknown profile."
      return
    else if (yield get_cluster_id data.cluster_name, data.secret_token, db)
      respond 403, "A cluster with that name already exists."
      return
    else
      # Create a cluster record to be stored in the server's database.
      record =
        status: "online"
        name: data.cluster_name
        public_domain: data.public_domain
        region: data.region
        deployments: []
        remotes: []

      # Store the record using a unique token as the key.
      cluster_id = make_key()
      yield db.clusters.put cluster_id, record

      # Add this cluster to the user's profile record.
      profile = yield db.profiles.get data.secret_token
      profile.clusters.push cluster_id
      yield db.profiles.put data.secret_token, profile

      try
        # Add Huxley master SSH key to the list of user SSH keys, for later access.
        data.public_keys.push yield get_master_key()

        # Create a CoreOS cluster using panda-cluster
        #pandacluster.create_cluster data
        respond 201, "Cluster creation underway.", {cluster_id}
      catch error
        # Record failure of this cluster.
        cluster = yield db.clusters.get cluster_id
        cluster.status = "failed"
        cluster.detail = error
        yield db.clusters.put cluster_id cluster


  put: async (context) ->
    # Parse the context for need information.
    {respond, data} = context
    data = yield data

    cluster = yield db.clusters.get data.cluster_id
    cluster.status = data.status
    cluster.detail = data.detail
    yield db.clusters.put data.cluster_id, cluster

    respond 200

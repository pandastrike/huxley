#===============================================================================
# Huxley API - Handlers - Clusters
#===============================================================================
# This file contains API handler functions for the collective resource "clusters".

{async} = require "fairmont"
{make_key, get_master_key, get_cluster_id, generate_cluster_master} = require "./helpers"
pandacluster = require "panda-cluster"

module.exports = (db) ->

  create: async (context) ->
    # Parse the context for needed information.
    {respond, data} = context
    data = yield data
    {token} = data.huxley

    # Validation.  Make sure the profile exists and the cluster name is not already in use.
    if (!token) || !(yield db.profiles.get token)
      respond 401, "Unknown profile."
      return
    else if (yield get_cluster_id data.cluster_name, token, db)
      respond 409, "A cluster with that name already exists."
      return
    else
      command = "cluster create #{data.cluster.name}"
      status = "creating"
      db.pending.put token, command, status

      # Store a cluster record using a unique token as the key.
      id = make_key()
      data.cluster_id = id
      yield db.clusters.put id,
        status: "starting"
        name: data.cluster.name
        public_domain: data.public_domain
        region: data.region
        deployments: []
        remotes: []
        command_id: command

      # Add this cluster to the user's profile record.
      profile = yield db.profiles.get token
      profile.clusters.push id
      yield db.profiles.put token, profile

      # Generate a master keypair for this cluster's agents.
      data.agent = yield generate_cluster_master cluster_id

      try
        # Add the Huxley API and Cluster Agent master SSH keys to the list of user SSH keys, for later access.
        data.public_keys.push yield get_master_key()
        data.public_keys.push data.agent.public

        # Create a CoreOS cluster using panda-cluster
        pandacluster.create_cluster data
        respond 201, "Cluster creation underway.", {id}
      catch error
        # Record failure of this cluster.
        cluster = yield db.clusters.get id
        cluster.status = "failed"
        cluster.detail = error
        yield db.clusters.put id, cluster
        db.pending.delete token, hash


  put: async (context) ->
    # Parse the context for needed information.
    {respond, data} = context
    data = yield data
    {token} = data.huxley
    console.log "**status input", data.status, data.detail
    if (!token) || !(yield db.profiles.get token)
      respond 401, "Unknown profile."
      return

    cluster = yield db.clusters.get data.cluster_id
    cluster.status = data.status
    cluster.detail = data.detail
    yield db.clusters.put data.cluster_id, cluster

    # Update pending commands list.
    if data.status == "online" || data.status == "stopped"
      command = cluster.command_id
      db.pending.delete token, command

    if data.status == "stopped"
      yield delete_cluster cluster.cluster_id, token, db

    respond 200

  list: async (context) ->
    {respond, request, data} = context
    data = yield data
    token = request.headers.authorization.split(" ")[1]

    profile = yield db.profiles.get token
    unless token && profile
      respond 401, "Unknown profile."
      return

    clusters = []
    clusters.push( yield db.clusters.get(id)) for id in profile.clusters
    respond 200, {clusters}

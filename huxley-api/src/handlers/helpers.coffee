#===============================================================================
# Huxley API - Handlers - Helpers
#===============================================================================
# This file contains helper functions for the Huxley API handlers.

{join} = require "path"

# PandaStrike Libraries
key_forge = require "key-forge" # cryptography
{async, read, remove} = require "fairmont"    # utility library

module.exports =
  # This creates a random authorization token, 16 bytes long and using characters safe for URLs.
  make_key: () -> key_forge.randomKey 16, "base64url"

  # Temporary measure.  Read in the master SSH public key from a file in this code's
  # path.  The key gets placed on every cluster this server creates.
  get_master_key: async () -> yield read join __dirname, "..", "huxley_master.pub"

  # Retrieve a cluster ID when given the name and who it belongs to.
  get_cluster_id: async (name, token, db) ->
    cluster_ids = (yield db.profiles.get token).clusters
    return id for id in cluster_ids when (name == (yield db.clusters.get(id))?.name)
    return false

  # Given a cluster name and profile token, lookup the cluster's ID.
  get_cluster: async (name, token, db, respond) ->

    # if name is actually cluster_id
#    cluster = yield db.clusters.get name
#    if cluster
#      return {
#        cluster_id: cluster_id
#        cluster: cluster
#      }

    # Lookup the cluster id using the info provided.
    unless yield db.profiles.get token
      respond 401, "Unknown profile."
      return null
    else
      cluster_ids = (yield db.profiles.get token).clusters
      for id in cluster_ids
        if name == (yield db.clusters.get(id))?.name
          cluster_id = id
          break

    # Lookup cluster data.
    unless cluster_id
      respond 404, "Cluster not found."
      return null
    else
      return {
        cluster_id: cluster_id
        cluster: yield db.clusters.get cluster_id
      }

  # Given a cluster name and profile token, lookup the cluster's ID.
  get_profile: async (token, db, respond) ->
    profile = (yield db.profiles.get token)
    if profile
      return profile
    else
      respond 401, "Unknown profile."
      return null

  # Delete a cluster and all its references from within our database.
  delete_cluster: async (cluster_id, token, db) ->
    db.clusters.delete cluster_id
    remove (yield db.profiles.get token).clusters, cluster_id

  # Retrieve the remote ID when given the cluster ID and the repository name.
  get_remote_id: async (name, cluster_id, db) ->
    remote_ids = (yield db.clusters.get cluster_id).remotes
    return id for id in remote_ids when (name == (yield db.remotes.get(id))?.repo_name)
    return false

  # Delete a remote and all of its references from within our database.
  delete_remote: async (remote_id, cluster_id, db) ->
    db.remotes.delete remote_id
    remove (yield db.clusters.get cluster_id).remotes, remote_id

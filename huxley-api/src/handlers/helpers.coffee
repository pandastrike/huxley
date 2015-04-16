#===============================================================================
# Huxley API - Handlers - Helpers
#===============================================================================
# This file contains helper functions for the Huxley API handlers.

{join} = require "path"

# PandaStrike Libraries
key_forge = require "key-forge" # cryptography
{async, read, remove, shell} = require "fairmont"    # utility library

module.exports =
  # This creates a random authorization token, 16 bytes long and using characters safe for URLs.
  make_key: () -> key_forge.randomKey 16, "base64url"

  # Temporary measure.  Read in the master SSH public key from a file in this code's
  # path.  The key gets placed on every cluster this server creates.
  get_master_key: async () -> yield read join __dirname, "..", "huxley_master.pub"

  # This creates an SSH master key to allow agents to connect to the cluster without holding a user's connection open for forwarding.
  generate_cluster_master: async (id) ->
    # Generate an SSH keypair that will serve as the API's master key.
    yield shell "ssh-keygen -t rsa -C 'cluster_agent_master' -N '' -f #{join process.env.HOME, ".huxley-agent-keys", id}"
    return {
      public: yield read join process.env.HOME, ".huxley-agent-keys", "#{id}.pub"
      private: yield read join process.env.HOME, ".huxley-agent-keys", id
    }


  # Retrieve a cluster ID when given the name and who it belongs to.
  get_cluster_id: async (name, token, db) ->
    cluster_ids = (yield db.profiles.get token).clusters
    return id for id in cluster_ids when (name == (yield db.clusters.get(id))?.name)
    return false

  # Given a cluster name and profile token, lookup the cluster's ID.
  get_cluster: async (name, token, db, respond) ->
    # Lookup the cluster id using the info provided.
    for id in (yield db.profiles.get token).clusters
      if name == (yield db.clusters.get(id)).name
        cluster_id = id
        break

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
    yield db.clusters.delete cluster_id
    profile = yield db.profiles.get token
    remove profile.clusters, cluster_id
    yield db.profiles.put token, profile

  # Retrieve the remote ID when given the cluster ID and the repository name.
  get_remote_id: async (name, cluster_id, db) ->
    remote_ids = (yield db.clusters.get cluster_id).remotes
    return id for id in remote_ids when (name == (yield db.remotes.get(id))?.repo_name)
    return false

  # Delete a remote and all of its references from within our database.
  delete_remote: async (remote_id, cluster_id, db) ->
    db.remotes.delete remote_id
    remove (yield db.clusters.get cluster_id).remotes, remote_id

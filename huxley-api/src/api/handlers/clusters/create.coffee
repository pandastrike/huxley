{async, md5} = require "fairmont"
key = require "../../key"
panda_cluster = require "panda-cluster"

module.exports = (db) ->
  async (context) ->
    # Parse the context for needed information.
    {respond, data} = context
    data = yield data
    {token} = data.huxley

    # Validation.  Make sure the profile exists and there's not name conflict.
    if (!token) || !(yield db.profiles.get token)
      respond 401, "Unknown profile."
      return
    else if (yield db.lookup.cluster.id( data.cluster.name, token, db))
      respond 409, "A cluster with that name already exists."
      return

    command = "cluster create #{data.cluster.name}"
    data.huxley.pending = hash = md5 command
    status = "creating"
    db.pending.put token, hash, status, command

    # Store a cluster record using a unique token as the key.
    data.cluster.id = id = key.generate()
    yield db.clusters.put id,
      status: "starting"
      name: data.cluster.name
      domain: data.cluster.zones.public
      type: data.cluster.type
      region: data.aws.region
      availability_zone: data.aws.availability_zone
      deployments: []
      remotes: []

    # Add this cluster to the user's profile record.
    profile = yield db.profiles.get token
    profile.clusters.push id
    yield db.profiles.put token, profile

    # Generate a master keypair for this cluster's agents.
    data.cluster.agent = yield key.ssh.generate()

    # Add the Huxley API and Cluster Agent master SSH keys to the key list.
    data.public_keys.push yield key.ssh.read()
    data.public_keys.push data.cluster.agent.public

    # Create a CoreOS cluster using panda-cluster
    panda_cluster.create data
    respond 201, "Cluster creation underway.", {id}

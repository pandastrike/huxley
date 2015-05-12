{async, md5} = require "fairmont"
panda_cluster = require "panda-cluster"

module.exports = (db) ->
  async (context) ->
    # Parse the context for needed information.
    {request, respond, data} = context
    data = yield data
    {name} = data.cluster
    {token} = data.huxley
    id = yield db.lookup.cluster.id name, token, db

    # Validation
    if (!token) || !(yield db.profiles.get token)
      respond 401, "Unknown profile."
      return
    else if !id
      respond 404
      return

    # Store this command in pending.
    command = "cluster delete #{name}"
    hash = md5 command
    status = "deleting"
    db.pending.put token, hash, status, command

    # Use panda-cluster to delete the cluster, and delete from database.
    panda_cluster.delete
      aws: (yield db.profiles.get token).aws
      cluster:
        name: name
        id: id
      huxley:
        url: data.huxley.url
        token: token
        pending: hash

    respond 200, {output: "Deletion underway."}

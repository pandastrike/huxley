{async, md5} = require "fairmont"
panda_cluster = require "./panda-cluster"

module.exports = (db) ->
  async (context) ->
    # Parse the context for needed information.
    {request, respond, match} = context
    {name} = match.path
    token = request.headers.authorization.split(" ")[1]
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
    cluster = yield db.cluster.get id
    panda_cluster.delete
      aws: profile.aws
      cluster:
        name: name
        id: id
      huxley:
        url: "https://#{request.headers.host}"
        token: token
        pending: hash

    respond 200, "Cluster deletion underway."

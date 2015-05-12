url = require "url"
{async, md5} = require "fairmont"
panda_cluster = require "panda-cluster"

module.exports = (db) ->
  async (context) ->
    # Parse the context for needed information.
    {request, respond, match} = context
    {name} = match.path
    token = request.headers.authorization.split(" ")[1]
    id = yield db.lookup.cluster.id name, token, db
    console.log context.request.url
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
        url: request.headers.host
        token: token
        pending: hash

    respond 200, "Cluster deletion underway."

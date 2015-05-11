
{async} = require "fairmont"

module.exports = (db) ->
  async (context) ->
    # Parse the context for needed information.
    {respond, data} = context
    data = yield data
    {id, status, detail} = data.cluster
    {token, pending} = data.huxley
    console.log "**Status:", status, detail

    # Validation
    if (!token) || !(yield db.profiles.get token)
      respond 401, "Unknown profile."
      return

    # Store new status data.
    cluster = yield db.clusters.get id
    cluster.status = status
    cluster.detail = detail
    yield db.clusters.put id, cluster

    # Update pending commands list if the status is terminal.
    if data.status == "online"
      db.pending.delete token, pending

    if data.status == "stopped"
      db.pending.delete token, pending
      yield db.remove.cluster id, token, db

    respond 200

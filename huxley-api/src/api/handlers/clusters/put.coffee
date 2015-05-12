{async} = require "fairmont"

module.exports = (db) ->
  async (context) ->
    # Parse the context for needed information.
    {respond, data} = context
    data = yield data
    {id, status, details} = data.cluster
    {token, pending} = data.huxley
    console.log "**Status:", status, details

    # Validation
    if (!token) || !(yield db.profiles.get token)
      respond 401, "Unknown profile."
      return

    # Store new status data.
    cluster = yield db.clusters.get id
    cluster.status = status
    cluster.details = details
    yield db.clusters.put id, cluster

    # Update pending commands list if the status is terminal.
    if status == "online"
      db.pending.delete token, pending

    if status == "stopped"
      db.pending.delete token, pending
      yield db.remove.cluster id, token, db

    respond 200

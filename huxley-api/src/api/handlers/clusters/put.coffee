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

    # Store new status data.  If shutting down or stopped, it's okay to skip this.
    try
      cluster = yield db.clusters.get id
      cluster.status = status
      cluster.details = details
      yield db.clusters.put id, cluster
    catch
      if status != "stopped" && status != "shutting down"
        throw new Error "Failed to store status."


    # Update pending commands list if the status is terminal.
    if status == "online" || status == "failed"
      db.pending.delete token, pending

    if status == "stopped"
      db.pending.delete token, pending
      yield db.remove.cluster id, token, db

    respond 200

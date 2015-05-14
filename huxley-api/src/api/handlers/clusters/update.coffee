{async} = require "fairmont"

module.exports = (db) ->
  console.log "This works 1"
  async (context) ->
    console.log "This works 2"
    # # Parse the context for needed information.
    # {respond, data} = context
    # data = yield data
    # {id, status, details} = data.cluster
    # {token, pending} = data.huxley
    # console.log "**Status for #{data.cluster.name}: #{status};  #{details}"
    #
    # # Validation
    # if (!token) || !(yield db.profiles.get token)
    #   respond 401, "Unknown profile."
    #   return
    #
    # # Store new status data.  If shutting down or stopped, it's okay to skip an
    # # update a create command...  happens if the user deletes a cluster before it's ready.
    # try
    #   cluster = yield db.clusters.get id
    #   unless (cluster.status == "shutting down" || cluster.status = "stopped") && status == "starting"
    #     cluster.status = status
    #     cluster.details = details
    #     yield db.clusters.put id, cluster
    # catch
    #   # Swallow the error here if the cluster record has already been destroyed.
    #   console.log "Failed to store status: #{status};  #{details}"
    #
    # # Update pending commands list if the status is terminal.
    # if status == "online" || status == "failed"
    #   db.pending.delete token, pending
    #
    # if status == "stopped"
    #   db.pending.delete token, pending
    #   yield db.remove.cluster id, token, db
    #
    # respond 200

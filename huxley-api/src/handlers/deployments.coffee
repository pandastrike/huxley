#===============================================================================
# Huxley API - Handlers - Deployments
#===============================================================================
# This file contains API handler functions for the collective resource "deployments".

{async} = require "fairmont"

module.exports = (db) ->
  create: async (context) ->
    # Parse the context for needed information.
    {respond, data} = context
    data = yield data
    {app, cluster, huxley} = data
    token = huxley.token

    # Validate the profile.
    unless token && (yield db.profiles.get token)
      respond 401, "Unknown profile."
      return

    # Store new deployment.
    yield db.deployments.put app.id,
      status: app.status

    # Associate this deployment with a cluster.
    cluster = yield db.clusters.get cluster.id
    cluster.deployments.push app.id
    yield db.clusters.put cluster.id, cluster

    # Store new pending record.
    db.pending.put token, "git push #{cluster.name} #{app.branch}", "starting"

    respond 201

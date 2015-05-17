#===============================================================================
# Huxley API - Handlers - Deployment
#===============================================================================
# This file contains API handler functions for the collective resource "deployment".

{async, md5} = require "fairmont"

module.exports = (db) ->
  # Update the status of an existing deployment.
  async (context) ->
    # Parse the context for needed information.
    {respond, data} = context
    data = yield data
    {app, cluster, huxley} = data
    {token} = huxley

    # Validate the profile.
    if (!token) || !(yield db.profiles.get token)
      respond 401, "Unknown profile."
      return

    # Update profile status
    deployment = yield db.deployments.get app.id
    deployment.status = app.status
    yield db.deployments.put app.id, deployment

    # Remove pending record if we've reached a terminal state.
    if app.status == "online" || app.status == "failed"
      db.pending.delete token, md5( "git push #{cluster.name} #{app.branch}" )

    respond 200

#===============================================================================
# Huxley API - Handlers - Deployments
#===============================================================================
# This file contains API handler functions for the collective resource "deployments".

{async} = require "fairmont"

module.exports = (db) ->
  # NOTE: deployments are created automatically when the first status
  # is POSTed. We include this endpoint for completeness's sake
  create: async ({respond, url, data}) ->
    {deployment_id, cluster_id} = yield data
    yield db.deployments.put deployment_id,
      id: deployment_id
      cluster_id
    respond 200, "Created", location: url "deployment", {deployment_id}

  query: async ({respond, match: {query}}) ->
    # Workaround for pandastrike/pbx#13
    respond 200, JSON.stringify yield db.deployments.all()

#===============================================================================
# Huxley API - Handlers - Status
#===============================================================================
# This file contains API handler functions for the collective resource "status".

{async} = require "fairmont"

module.exports = (db) ->
  post: async ({respond, data}) ->
    {deployment_id, cluster_id, application_id, service} = status = yield data
    deployment = yield db.deployments.get deployment_id

    # create deployment if not exists
    unless deployment?
      deployment = {id: deployment_id, cluster_id, application_id}

    # add status to appropriate queue
    deployment.services ?= {}
    deployment.services[service] ?= []
    deployment.services[service].push status

    # save changes
    yield db.deployments.put deployment_id, deployment
    respond 201, "Created" # no url

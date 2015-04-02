#===============================================================================
# Huxley API - Handlers - Deployment
#===============================================================================
# This file contains API handler functions for the collective resource "deployment".

{async} = require "fairmont"

module.exports = (db) ->
  get: async ({respond, match: {path: {deployment_id}}}) ->
    deployment = yield db.deployments.get deployment_id
    if deployment?
      # workaround for pandastrike/pirate#23
      deployment = clone deployment
      for service, status of deployment.services
        {status, detail, timestamp} = last status
        deployment.services[service] = {status, detail, timestamp}
      respond 200, deployment
    else
      respond.not_found()

  delete: async ({respond, match: {path: {deployment_id}}}) ->
    deployment = yield db.deployments.get deployment_id
    if deployment?
      yield db.deployments.delete deployment_id
      respond 200, "Deleted"
    else
      respond.not_found()

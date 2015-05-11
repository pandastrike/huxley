#===============================================================================
# Huxley API - Handlers - Deployments
#===============================================================================
# This file contains API handler functions for the collective resource "deployments".

module.exports = (db) ->
  create: (require "./create")(db)
  update: (require "./update")(db)

#===============================================================================
# Huxley API - Handlers - Cluster
#===============================================================================
# This file contains API handler functions for the single resource "cluster".

module.exports = (db) ->
  delete: (require "./delete")(db)
  get: (require "./get")(db)

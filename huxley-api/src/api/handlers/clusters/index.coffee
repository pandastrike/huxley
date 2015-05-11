#===============================================================================
# Huxley API - Handlers - Clusters
#===============================================================================
# This file contains API handler functions for the collective resource "clusters".

module.exports = (db) ->
  create: (require "./create")(db)
  put: (require "./put")(db)
  list: (require "./list")(db)

#===============================================================================
# Huxley API - Helpers - Database Lookup
#===============================================================================
# Huxley stores the data it tracks in a normalized format.  While Pirate makes
# it easy to lookup data directly from its collection, Pirate does not support
# more sophisticated querying on the database.  Until that is added, these
# functions bridge the gap and provide a data lookup with an indirect reference.
{async} = require "fairmont"

module.exports =
  cluster:
    # Retrieve a cluster ID when given the cluster's name and owner.
    id: async (name, token, db) ->
      ids = (yield db.profiles.get token).clusters
      return id for id in ids when (name == (yield db.clusters.get(id))?.name)
      return false  # If we fail.

  remote:
    id: async (name, cluster_id, db) ->
      ids = (yield db.clusters.get cluster_id).remotes
      return id for id in ids when (name == (yield db.remotes.get(id))?.app.name)
      return false  # If we fail.

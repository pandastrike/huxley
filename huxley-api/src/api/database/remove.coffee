#===============================================================================
# Huxley API - Helpers - Database Record Deletion
#===============================================================================
# Huxley stores the data it tracks in a normalized format.  While Pirate makes
# it easy to delete data directly from its collection, Pirate does not support
# more sophisticated querying on the database.  Until that is added, these
# functions bridge the gap.  They provide a way to delete all data associated with
# an entity with a single command in the handler.
{async, remove} = require "fairmont"

module.exports =
  # Delete a cluster and all its references.
  cluster: async (id, token, db) ->
    # Direct removal
    yield db.clusters.delete id

    # Remove reference from profile collection.
    profile = yield db.profiles.get token
    remove profile.clusters, id
    yield db.profiles.put token, profile


  # Delete a remote and all of its references. 
  remote: async (id, cluster, db) ->
    # Direct removal
    yield db.remotes.delete id

    # Remove reference from cluster collection.
    record = yield db.clusters.get cluster
    remove record.remotes, id
    yield db.clusters.put cluster, record

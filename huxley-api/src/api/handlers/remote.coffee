#===============================================================================
# Huxley API - Handlers - Remote
#===============================================================================
# This file contains API handler functions for the collective resource "remote".
{async} = require "fairmont"
pandahook = require "panda-hook"

module.exports = (db) ->
  # Use panda-hook to delete a repository on the cluster's hook server.
  delete: async (context) ->
    {request, respond, match} = context
    {cluster_id, repo_name} = yield match.path
    token = request.headers.authorization.split(" ")[1]
    id = yield db.lookup.remote.id repo_name, cluster_id, db

    # Validation
    if !id
      respond 404, "Unknown remote."
      return

    yield pandahook.destroy yield db.remotes.get(id)
    yield db.remove.remote id, cluster_id, db
    respond 200, "remote repository deleted. git alias removed."

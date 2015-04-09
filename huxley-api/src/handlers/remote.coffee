#===============================================================================
# Huxley API - Handlers - Remote
#===============================================================================
# This file contains API handler functions for the collective resource "remote".

{async} = require "fairmont"
pandahook = require "panda-hook"

{get_remote_id, delete_remote} = require "./helpers"


module.exports = (db) ->

  # This function uses panda-hook to delete a repository on the cluster's hook server.
  delete: async (context) ->
    {request, respond, match} = context
    {cluster_id, repo_name} = yield match.path
    token = request.headers.authorization.split(" ")[1]

    # Accquire the remote's ID based on the provided information.
    id = yield get_remote_id repo_name, cluster_id, db

    # Lookup the record about this remote using its ID.
    remote = yield db.remotes.get id

    # Use panda-hook to delete the remote repository.
    if remote?
      #yield pandahook.destroy remote
      yield delete_remote
      respond 200, "remote repository deleted. git alias removed."
    else
      respond 404, "unknown remote repository ID."

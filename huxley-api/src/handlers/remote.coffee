#===============================================================================
# Huxley API - Handlers - Remote
#===============================================================================
# This file contains API handler functions for the collective resource "remote".

{async} = require "fairmont"
pandahook = require "panda-hook"


module.exports = (db) ->

  # This function uses panda-hook to delete a repository on the cluster's hook server.
  delete: async (request) ->
    {respond, match: {path: {remote_id}}} = request
    remote_id = yield remote_id
    # TODO validation

    # Lookup info about this remote using its ID.
    remote = yield db.remotes.get remote_id

    # Use panda-hook to delete the remote repository.
    if remote?
      yield pandahook.destroy remote
      respond 200, "remote repository deleted. git alias removed."
    else
      respond 404, "unknown remote repository ID."

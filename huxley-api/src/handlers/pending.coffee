#===============================================================================
# Huxley API - Handlers - Pending
#===============================================================================
# This file contains API handler functions for the single resource "pending".

{async} = require "fairmont"
{make_key} = require "./helpers"

module.exports = (db) ->

  # Return a list of pending items associated with the profile.
  get: async (context) ->
    # Parse the context for needed information.
    {request, respond, match} = context
    token = request.headers.authorization.split(" ")[1]

    # Access the user's profile.
    profile = yield db.profiles.get token

    if !profile
      respond 401, "Unknown profile."
    else
      resources = db.pending.get_all token
      respond 200, {resources}

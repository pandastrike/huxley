#===============================================================================
# Huxley API - Handlers - Pending
#===============================================================================
# This file contains API handler functions for the single resource "pending".
{async} = require "fairmont"

module.exports = (db) ->

  # Return a list of pending items associated with the profile.
  get: async (context) ->
    # Parse the context for needed information.
    {request, respond, match} = context
    token = request.headers.authorization.split(" ")[1]

    # Validation
    if (!token) || !(yield db.profiles.get token)
      respond 401, "Unknown profile."
      return

    respond 200, {resources: db.pending.list token}

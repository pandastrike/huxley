#===============================================================================
# Huxley API - Handlers - Profile
#===============================================================================
# This file contains API handler functions for the single resource "profile".

{async} = require "fairmont"

module.exports = (db) ->

  get: async (context) ->
    {request, respond, match} = context
    token = request.headers.authorization.split(" ")[1]

    if (!token) || !(yield db.profiles.get token)
      respond 401, "Unknown profile."
      return

    # Return the database record concerning this profile.
    respond 200, {profile: yield db.profiles.get token}

#===============================================================================
# Huxley API - Handlers - Profile
#===============================================================================
# This file contains API handler functions for the single resource "profile".

{async} = require "fairmont"

module.exports = (db) ->

  get: async (context) ->
    {request, respond, match} = context
    token = request.headers.authorization.split(" ")[1]

    if !token
      respond 401, "No token specified"

    profile = yield db.profiles.get token
    if profile
      # Return the database record concerning this profile.
      respond 200, {profile}
    else
      respond 404

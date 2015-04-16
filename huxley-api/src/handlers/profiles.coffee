#===============================================================================
# Huxley API - Handlers - Profiles
#===============================================================================
# This file contains API handler functions for the collective resource "profiles".

{async} = require "fairmont"
{make_key} = require "./helpers"

module.exports = (db) ->

  create: async (context) ->
    {respond, data} = context
    data = yield data
    {name, email} = data.profile

    # Create a new user profile and save.
    token = make_key()
    yield db.profiles.put token,
      name: name
      email: email
      clusters: []

    # Return token to client.
    respond 201, "Profile created.", {token}

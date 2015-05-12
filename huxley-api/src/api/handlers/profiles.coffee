#===============================================================================
# Huxley API - Handlers - Profiles
#===============================================================================
# This file contains API handler functions for the collective resource "profiles".
{async} = require "fairmont"
key = require "../key"

module.exports = (db) ->

  create: async (context) ->
    {respond, data} = context
    data = yield data
    {name, email} = data.profile

    # Create a new user profile and save.
    token = key.generate()
    yield db.profiles.put token,
      aws: data.aws
      name: name
      email: email
      clusters: []

    # Return token to client.
    respond 201, "Profile created.", {token}

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

    # Create a new user profile
    profile =
      name: data.profile_name
      email: data.email
      clusters: []

    # Save the profile and return a copy to client.
    secret_token = make_key()
    yield db.profiles.put secret_token, profile
    respond 201, "Profile created.", {secret_token}

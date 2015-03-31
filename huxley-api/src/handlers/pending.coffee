#===============================================================================
# Huxley API - Handlers - Pending
#===============================================================================
# This file contains API handler functions for the single resource "pending".

{async} = require "fairmont"
{make_key} = require "./helpers"

module.exports = (db) ->

  pending:

    # Return a list of pending items associated with the profile.
    get: async (context) ->
      # Parse the context for needed information.
      {request, respond, match} = context
      token = request.headers.authorization.split(" ")[1]

      # Access the user's profile.
      profile = yield db.profiles.get token

      if !profile
        respond 404
        return

      # Begin collecting data about this profile.
      resources = []

      # Clusters
      for id in profile.clusters
        cluster = db.clusters.get id
        resources.push "Cluster #{id} has status #{cluster.status}. #{cluster.detail}"

      respond 200, {resources}

{async} = require "fairmont"

module.exports = (db) ->
  async (context) ->
    {respond, request, data} = context
    data = yield data
    token = request.headers.authorization.split(" ")[1]

    profile = yield db.profiles.get token
    unless token && profile
      respond 401, "Unknown profile."
      return

    clusters = []
    clusters.push( yield db.clusters.get(id)) for id in profile.clusters
    respond 200, {clusters}

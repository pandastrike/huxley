{async} = require "fairmont"

module.exports = (db) ->
  async (context) ->
    # Parse the context for needed information.
    {request, respond, match} = context
    {name} = match.path
    token = request.headers.authorization.split(" ")[1]
    id = yield db.lookup.cluster.id name, token, db

    # Validation
    if (!token) || !(yield db.profiles.get token)
      respond 401, "Unknown profile."
      return
    else if !id
      respond 404
      return

    # Retrieve cluster data.
    respond 200, {id, cluster: yield db.cluster.get id}

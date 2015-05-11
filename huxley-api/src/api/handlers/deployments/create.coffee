{async} = require "fairmont"

module.exports = (db) ->
  create: async (context) ->
    # Parse the context for needed information.
    {respond, data} = context
    data = yield data
    {app, cluster, huxley} = data
    token = huxley.token

    # Validate the profile.
    if (!token) || !(yield db.profiles.get token)
      respond 401, "Unknown profile."
      return

    # Store new pending record.
    command = "git push #{cluster.name} #{app.branch}"
    hash = md5 command
    status = "starting"
    db.pending.put token, hash, status, command

    # Store new deployment.
    yield db.deployments.put app.id,
      status: app.status

    respond 201

    # TODO: Associate this deployment with a cluster... eventually Huxley will
    #   support killing deployments, so we'll need to track them there.

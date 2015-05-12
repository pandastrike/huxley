# Instantiate Huxley's database interface via Pirate.

{async} = require "fairmont"
Pending = require "./pending"

module.exports = async () ->
    #adapter = Redis.Adapter.make(host: "192.168.59.103")  # Local Machine
    adapter = Redis.Adapter.make(host: "172.17.42.1")    # Docker Container
    adapter.connect()

    # Database Collection Declarations
    return {
      clusters: yield adapter.collection "clusters"
      deployments: yield adapter.collection "deployments"
      profiles: yield adapter.collection "profiles"
      remotes: yield adapter.collection "remotes"
      pending: new Pending
    }

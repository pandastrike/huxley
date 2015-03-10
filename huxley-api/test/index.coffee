{discover} = (require "pbx").client
amen = require "amen"
assert = require "assert"

amen.describe "Huxley API", (context) ->

  context.test "Create a user", (context) ->

    api = yield discover "http://localhost:8080"

    {response: {headers: {location}}} =
      yield api.clusters.create
        name: "test-cluster"
        email: "test@pandastrike.com"
        url: "tipsy-tester"

    cluster = (api.cluster location)

    context.test "Retrieve cluster", ->

      {data} = yield cluster.get()
      console.log yield data

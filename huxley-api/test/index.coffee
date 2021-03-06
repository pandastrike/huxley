{discover} = (require "pbx").client
amen = require "amen"
assert = require "assert"
{w} = require "fairmont"

amen.describe "Huxley API", (context) ->

  #-------------------------------------------------------
  # User functionality is commented out in handlers.coffee
  #-------------------------------------------------------
  # context.test "Create a user", (context) ->
  #
  #   api = yield discover "http://localhost:8080"
  #
  #   {response: {headers: {location}}} =
  #     yield api.clusters.create
  #       name: "test-cluster"
  #       email: "test@pandastrike.com"
  #       url: "tipsy-tester"
  #
  #   cluster = (api.cluster location)
  #
  #   context.test "Retrieve cluster", ->
  #
  #     {data} = yield cluster.get()
  #     console.log yield data

  context.test "Post a status", (context) ->
    Status =
      cluster_id: "tipsy-tester"
      application_id: "abcdef"
      deployment_id: "deadbeef"
      service: "node"
      status: "starting"
      detail: foo: "bar"
      timestamp: Date.now()

    api = yield discover "http://localhost:8080"

    # deployment does not need to exist, it is created automaticaly
    {response} = api.status.post Status

    context.test "Retrieve deployment information", ->
      deployment = api.deployment "deadbeef"
      {data} = yield deployment.get()
      response = yield data

      assert.equal response.id, Status.deployment_id
      assert.equal response.cluster_id, Status.cluster_id
      assert.equal response.application_id, Status.application_id
      assert response.services?
      assert typeof response.services == 'object'
      for property in w 'status detail timestamp'
        assert.deepEqual response.services[Status.service][property], Status[property]

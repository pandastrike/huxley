{call} = require "when/generator"
amen = require "amen"
assert = require "assert"

cson = require "c50n"
{read} = require "fairmont"
{resolve} = require "path"

pbx = require "../src/pbx"

pandaconfig = null

call ->
  try
    pandaconfig = yield cson.parse (read(resolve("#{process.env.HOME}/.pandacluster.cson")))
  catch error
    assert.fail error, null, "Credential file ~/.pandacluster.cson missing"

amen.describe "Huxley API", (context) ->

  cluster_name = "peter-cli-test"
  secret_token = null
  cluster_url = null
  {url, email, key_pair, public_keys} = pandaconfig

  context.test "Create a user", (context) ->
  
    user = (yield pbx.create_user pandaconfig)
    {secret_token} = (JSON.parse user).user

    #console.log "*****secret token sent: ", secret_token
    assert.ok user
    assert.ok secret_token

    context.test "Create a cluster", ->
      pandaconfig.cluster_name = cluster_name
      pandaconfig.secret_token = secret_token
      location =
        (yield pbx.create_cluster pandaconfig)
        #(yield pbx.create_cluster {cluster_name, email, secret_token, url, key_pair, public_keys})

      cluster_url = location
      assert.ok cluster_url

      console.log "*****cluster created, cluster_url: ", cluster_url

#      cluster_status =
#        (yield pbx.get_cluster_status {cluster_url, secret_token, url})
#
#      console.log "*****cluster_status: ", cluster_status
#      assert.ok cluster_status

      cluster_status =
        (yield pbx.wait_on_cluster {cluster_url, secret_token, url})

      console.log "*****cluster_status is done: ", cluster_status
      assert.ok cluster_status

      context.test "Delete a cluster", ->
        url = pandaconfig.url

        response = (yield pbx.delete_cluster {cluster_url, secret_token, url})
        console.log "***** done deleting"

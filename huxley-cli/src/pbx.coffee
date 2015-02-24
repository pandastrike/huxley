{promise, lift} = require "when"
{liftAll} = require "when/node"
async = (require "when/generator").lift

{read, write} = require "fairmont"
{resolve} = require "path"

#Configurator = require "../../node_modules/panda-config/src/index.coffee"
Configurator = require "panda-config"

config_path = resolve("#{process.env.HOME}/.pandacluster.cson")

{parse} = require "c50n"

{discover} = require "./client"

# This is a wrap of setTimeout with ES6 technology that forces a non-blocking
# # pause in execution for the specified duration (in ms).
pause = (duration) ->
 promise (resolve, reject) ->
   callback = -> resolve()
   setTimeout callback, duration


# Lift Node's async read/write functions.
{read_file, write_file} = do ->
  {readFile, writeFile} = liftAll(require "fs")

  read_file: async (path) ->
    (yield readFile path, "utf-8").toString()

  write_file: (path, content) ->
    writeFile path, content, "utf-8"

module.exports =

  #create_cluster: async ({cluster_name, email, secret_token, url}) ->
  create_cluster: async (args) ->
    {url} = args

    api = (yield discover url)
    clusters = (api.clusters)
    {response: {headers: {location}}}  =
      (yield clusters.create args)
    location
    console.log "*****Created cluster ID: ", location

  delete_cluster: async ({cluster_url, secret_token, url}) ->

    api = (yield discover url)
    cluster = (api.cluster cluster_url)
    result = (yield cluster.delete())

  get_cluster_status: async ({cluster_url, secret_token, url}) ->

    api = (yield discover url)
    cluster = (api.cluster cluster_url)
    {data} = (yield cluster.get())
    data = (yield data)
    console.log "*****Cluster status: ", data

  wait_on_cluster: async ({cluster_url, secret_token, url}) ->

    api = (yield discover url)
    cluster = (api.cluster cluster_url)
    while true
      {data} = (yield cluster.get())
      {cluster_status} = yield data
      if(cluster_status.message == "The cluster is confirmed to be online and ready.")
        return cluster_status # The cluster formation complete.
      else
        yield pause 5000  # Not complete, keep going.

  # FIXME: filter out secret keys in response
  create_user: async ({aws, email, url, key_pair, public_keys}) ->

    api = (yield discover url)
    users = (api.users)
    {data} = (yield users.create {aws, email, key_pair, public_keys})
    data = (yield data)
    secret_token = (JSON.parse data).user.secret_token

    configurator = Configurator.make
      prefix: "."
      paths: [ process.env.HOME ]
    configuration = configurator.make name: "huxley"
    yield configuration.load()
    configuration.data.secret_token = secret_token
    configuration.save()
    console.log configuration.data

    secret_token

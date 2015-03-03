#===============================================================================
# Modules
#===============================================================================
# Core Libraries
{resolve} = require "path"

# PandaStrike Libraries
{read, write} = require "fairmont"      # utility helpers
Configurator = require "panda-config"   # config file parsing
{discover} = require "./client"         # PBX component

# Third Party Libraries
{promise, lift} = require "when"        # promise library
{liftAll} = require "when/node"
async = (require "when/generator").lift


#===============================================================================
# Helpers
#===============================================================================
# This is a wrap of setTimeout with ES6 technology that forces a non-blocking
# pause in execution for the specified duration (in ms).
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


#===============================================================================
# Module Definition
#===============================================================================
module.exports =

  #create_cluster: async ({cluster_name, email, secret_token, url}) ->
  create_cluster: async (args) ->
    {url} = args
    console.log "Inside interface create", url
    api = (yield discover url)
    clusters = (api.clusters)
    {response: {headers: {location}}}  =
      (yield clusters.create args)
    location
    console.log "*****Created cluster ID: ", location

  delete_cluster: async ({cluster_id, secret_token, url}) ->

    api = (yield discover url)
    cluster = (api.cluster cluster_id)
    result = (yield cluster.delete())

  get_cluster_status: async ({cluster_id, secret_token, url}) ->

    api = (yield discover url)
    cluster = (api.cluster cluster_id)
    {data} = (yield cluster.get())
    data = (yield data)
    console.log "*****Cluster status: ", data

  wait_on_cluster: async ({cluster_id, secret_token, url}) ->

    api = (yield discover url)
    cluster = (api.cluster cluster_id)
    while true
      {data} = (yield cluster.get())
      {cluster_status} = yield data
      if(cluster_status.message == "The cluster is confirmed to be online and ready.")
        return cluster_status # The cluster formation complete.
      else
        yield pause 5000  # Not complete, keep going.

  add_remote: async (spec) ->
    {url} = spec

    api = yield discover url
    remotes = api.remotes
    result = yield remotes.create spec
    console.log result

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

    secret_token
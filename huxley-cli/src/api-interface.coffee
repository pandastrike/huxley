#===============================================================================
# Modules
#===============================================================================
# Core Libraries
{resolve} = require "path"

# PandaStrike Libraries
{sleep} = require "fairmont"      # utility helpers
Configurator = require "panda-config"   # config file parsing
{discover} = require "./client"         # PBX component

# Third Party Libraries
async = (require "when/generator").lift # promise library


#===============================================================================
# Helpers
#===============================================================================
# Prepare a basic error object to return to the UI.
build_error = (message, value) ->
  return {
    message: message
    value: value
  }



#===============================================================================
# Module Definition
#===============================================================================
module.exports =

  #create_cluster: async ({cluster_name, email, secret_token, url}) ->
  create_cluster: async (spec) ->
    {url} = spec

    api = yield discover url
    clusters = api.clusters

    {response: {headers: {location}}}  = yield clusters.create spec
    console.log "*****Created cluster ID: ", location

  delete_cluster: async (spec) ->
    {url} = spec

    api = yield discover url
    cluster = api.cluster
    result = yield cluster.delete spec
    console.log result

  poll_cluster: async (spec) ->
    {url} = spec

    api = yield discover url
    cluster = api.cluster
    while true
      response = yield cluster.get spec
      {cluster_status} = yield response
      console.log "*****Cluster status: ", cluster_status.data
      if cluster_status.message == "The cluster is confirmed to be online and ready."
        return cluster_status # The cluster formation complete.
      else
        yield sleep 5000  # Not complete, keep going.

  add_remote: async (spec) ->
    try
      {url} = spec
      api = yield discover url
      remotes = api.remotes
      {response: {headers: {remote_id}}}  = yield remotes.create spec
      console.log "*****Created githook ID: ", remote_id
      return {
        remote_id: remote_id
      }

    catch error
      throw build_error "Unable to install remote githook.", error

  rm_remote: async (spec) ->
    try
      {url} = spec
      api = yield discover url
      remote = api.remote spec.remote_id
      result = yield remote.delete()
      console.log yield result.data

    catch error
      throw build_error "Unable to remove remote githook.", error

  #-------------------------------------------------
  # code related to "user" functionality
  #-------------------------------------------------
  # # FIXME: filter out secret keys in response
  # create_user: async ({aws, email, url, key_pair, public_keys}) ->
  #
  #   api = (yield discover url)
  #   users = (api.users)
  #   {data} = (yield users.create {aws, email, key_pair, public_keys})
  #   data = (yield data)
  #   secret_token = (JSON.parse data).user.secret_token
  #
  #   configurator = Configurator.make
  #     prefix: "."
  #     paths: [ process.env.HOME ]
  #   configuration = configurator.make name: "huxley"
  #   yield configuration.load()
  #   configuration.data.secret_token = secret_token
  #   configuration.save()
  #
  #   secret_token

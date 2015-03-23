# This is the client's interface to the Huxley API.  Objects are transported from
# here to the server and the results are interpreted.  The interface functions
# are grouped based on which resource they affect.
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

  #--------------------------------
  # Cluster
  #--------------------------------
  create_cluster: async (spec) ->
    try
      api = yield discover spec.url
      clusters = api.clusters
      {response: {headers: {cluster_id}}}  = yield clusters.create spec
      console.log "*****Creation In Progress. \nName: #{spec.cluster_name} \nCluster ID: #{cluster_id}"
      return {cluster_id: cluster_id}
    catch error
      throw build_error "Unable to construct Huxley cluster.", error

  delete_cluster: async (spec) ->
    try
      api = yield discover spec.url
      cluster = api.cluster spec.cluster_id
      yield cluster.delete()
      console.log "****Deletion In Progress."
    catch error
      throw build_error "Unable to delete Huxley cluster.", error

  poll_cluster: async (spec) ->
    api = yield discover spec.url
    cluster = api.cluster spec.cluster_id
    while true
      response = yield cluster.get()
      data = yield response.data
      console.log "*****Cluster status: ", data.cluster_status
      if data.cluster_status == "The cluster is confirmed to be online and ready."
        return data.cluster_status # The cluster formation complete.
      else
        yield sleep 5000  # Not complete, keep going.


  #--------------------------------
  # Remote
  #--------------------------------
  add_remote: async (spec) ->
    try
      api = yield discover spec.url
      remotes = api.remotes
      {response: {headers: {remote_id}}}  = yield remotes.create spec
      console.log "*****Githook installed on cluster #{spec.cluster_name} \nID: #{remote_id}"
      return {remote_id: remote_id}

    catch error
      throw build_error "Unable to install remote githook.", error

  rm_remote: async (spec) ->
    try
      api = yield discover spec.url
      remote = api.remote spec.remote_id
      result = yield remote.delete()
      console.log yield result.data

    catch error
      throw build_error "Unable to remove remote githook.", error

  #-------------------------------------------------
  # code related to "profile" functionality
  #-------------------------------------------------
  # FIXME: filter out secret keys in response
  create_profile: async (request_data) ->
    try
      {url} = request_data.config.huxley
      api = (yield discover url)
      profiles = (api.profiles)
      {data} = (yield profiles.create {data: request_data})
      data = (yield data)
      {secret_token} = (JSON.parse data).profile
      console.log "*****creating profile: ", request_data.email
      console.log "*****secret token: ", secret_token
    
      configurator = Configurator.make
        prefix: "."
        paths: [ process.env.HOME ]
      configuration = configurator.make name: "huxley"
      yield configuration.load()
      configuration.data.secret_token = secret_token
      configuration.save()
    
      secret_token
    catch error
      throw "Something done broke in profile creation: #{error}"

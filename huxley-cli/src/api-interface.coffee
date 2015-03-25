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

  #--------------------------------
  # Pending
  #--------------------------------
  list_pending: async (spec) ->
    try
      {config} = spec
      {secret_token} = config
      {url} = spec.config.huxley
      api = (yield discover url)

      # Get profile, parse for cluster ids
      profile = (api.profile {secret_token})
      {data} = (yield profile.get())
      clusters_results = (yield data).profile.clusters

      # Get cluster status, parse list of deployments for said cluster
      deployments_results = {}
      for cluster_id, cluster_name of clusters_results
        cluster = (api.cluster {cluster_id})
        {data} = (yield cluster.get())
        data = (yield data)
        result = (JSON.parse data).deployments
        deployments[cluster_id] = result

      # Get deployment status
      pending_results = []
      for cluster_id, deployments_list of deployments_results
        for deployment_id in deployments_list
          deployment = (api.deployment {deployment_id})
          {data} = (yield deployment.get())
          data = (yield data)
          result = (JSON.parse data)
          # FIXME: how to present return data (group by cluster_id?)
          pending_results.push data

      pending_results

    catch error
      throw "Something done broke in list pending: #{error}"

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
      {profile} = (JSON.parse data)
      console.log "*****profile created: ", profile

      {secret_token} = profile
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

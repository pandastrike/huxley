#===============================================================================
# Huxley - CLI Interface to the API
#===============================================================================
# This is the client's interface to the Huxley API.  Objects are transported from
# here to the server and the results are interpreted.  The interface functions
# are grouped based on which resource they affect.

# Core Libraries
{resolve} = require "path"

# PandaStrike Libraries
{async} = require "fairmont"      # utility helpers
{discover} = require "./client"         # PBX component

# Huxley Components
{build_error} = require "./helpers"


module.exports =
  #--------------------------------
  # Cluster
  #--------------------------------
  create_cluster: async (spec) ->
    try
      clusters = (yield discover spec.url).clusters
      {response: {headers: {cluster_id}}} = yield clusters.create spec
      console.log "*****Creation In Progress. \nName: #{spec.cluster_name} \nCluster ID: #{cluster_id}"
      return {cluster_id}
    catch error
      throw build_error "Unable to construct Huxley cluster.", error

  delete_cluster: async (spec) ->
    try
      cluster = (yield discover spec.url).cluster spec.cluster_name
      yield cluster.delete
        .authorize bearer: spec.secret_token
        .invoke()
      console.log "****Deletion In Progress."
    catch error
      throw build_error "Unable to delete Huxley cluster.", error

  get_cluster: async (spec) ->
    try
      cluster = (yield discover spec.url).cluster spec.cluster_name
      {data} = yield cluster.get
        .authorize bearer: spec.secret_token
        .invoke()
      return data
    catch error
      throw build_error "Unable to retrieve cluster data.", error

  #--------------------------------
  # Remote
  #--------------------------------
  add_remote: async (spec) ->
    try
      remotes = (yield discover spec.url).remotes
      {response: {headers: {remote_id}}}  = yield remotes.create spec
      console.log "*****Githook installed on cluster #{spec.cluster_name} \nID: #{remote_id}"
    catch error
      throw build_error "Unable to install remote githook.", error

  rm_remote: async (spec) ->
    try
      {cluster_id, repo_name} = spec
      remote = (yield discover spec.url).remote {cluster_id, repo_name}
      yield remote.delete
        .authorize bearer: spec.secret_token
        .invoke()
      console.log "****Githook remote has been removed."
    catch error
      throw build_error "Unable to remove remote githook.", error

  #--------------------------------
  # Pending
  #--------------------------------
  list_pending: async (spec) ->
    try
      pending = (yield discover spec.url).pending
      {data} = yield pending.get
        .authorize bearer: spec.secret_token
        .invoke()
      return data
    catch error
      throw "Something done broke in list pending: #{error}"

  #-------------------------------------------------
  # Profile
  #-------------------------------------------------
  create_profile: async (spec) ->
    try
      profiles = (yield discover spec.url).profiles
      {response: {headers: {secret_token}}} = yield profiles.create spec
      console.log "*****profile \"#{spec.profile_name}\" created. Secret token stored."
      return yield {secret_token}
    catch error
      throw build_error "Unable to create profile.", error

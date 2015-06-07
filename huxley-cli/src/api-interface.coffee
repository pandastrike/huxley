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
{discover} = (require "pbx").client    # PBX component

# Huxley Components
{build_error} = require "./helpers"


module.exports =

  cluster:
    create: async (spec) ->
      try
        clusters = (yield discover spec.huxley.url).clusters
        {response: {headers: {id}}} = yield clusters.create spec
        return "Cluster creation In Progress. \nName: #{spec.cluster.name} \nCluster ID: #{id}"
      catch error
        throw build_error "Unable to construct Huxley cluster.", error

    delete: async (spec) ->
      try
        cluster = (yield discover spec.huxley.url).cluster spec.cluster.name
        {data} = yield cluster.delete spec
        data = yield data
        data.message = "Cluster deletion In Progress."
        return data
      catch error
        throw build_error "Unable to delete Huxley cluster.", error

    get: async (spec) ->
      try
        cluster = (yield discover spec.huxley.url).cluster spec.cluster.name
        {data} = yield cluster.get
          .authorize bearer: spec.huxley.token
          .invoke()
        return data
      catch error
        throw build_error "Unable to retrieve cluster data.", error


    list: async (spec) ->
      try
        clusters = (yield discover spec.huxley.url).clusters
        {data} = yield clusters.list
          .authorize bearer: spec.huxley.token
          .invoke()
        return data
      catch error
        throw build_error "Unable to retrieve clusters list data.", error


  remote:
    create: async (spec) ->
      try
        remotes = (yield discover spec.huxley.url).remotes
        {response: {headers: {id}}}  = yield remotes.create spec
        return "Githook installed on cluster #{spec.cluster.name} \nID: #{id}"
      catch error
        throw build_error "Unable to install remote githook.", error

    delete: async (spec) ->
      try
        remote = (yield discover spec.huxley.url).remote {cluster_id: spec.cluster.id, repo_name: spec.app.name}
        yield remote.delete
          .authorize bearer: spec.huxley.token
          .invoke()
        return "Githook remote has been removed."
      catch error
        throw build_error "Unable to remove remote githook.", error

  pending:
    list: async (spec) ->
      try
        pending = (yield discover spec.huxley.url).pending
        {data} = yield pending.get
          .authorize bearer: spec.huxley.token
          .invoke()
        return yield data
      catch error
        throw build_error "Unable to retrieve pending commands.", error

  profile:
    create: async (spec) ->
      try
        profiles = (yield discover spec.huxley.url).profiles
        {response: {headers: {token}}} = yield profiles.create spec
        return {
          message: "*****profile \"#{spec.profile.name}\" created. Secret token stored."
          token: token
        }
      catch error
        throw build_error "Unable to create profile.", error

#    get: async (spec) ->
#      try
#        {secret_token} = spec
#        profile = (yield discover spec.url).profile #secret_token
#        {data} = yield profile.get
#          .authorize bearer: spec.secret_token
#          .invoke()
#        return yield data
#      catch error
#        throw build_error "Unable to get profile.", error

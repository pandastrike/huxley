#===============================================================================
# Modules
#===============================================================================
# PandaStrike Libraries
{Memory} = require "pirate"               # database adapter
key_forge = require "key-forge"           # cryptography
{read} = require "fairmont"               # utils and functional helper library

# Third Party Libraries
async = (require "when/generator").lift   # promise library
{call} = require "when/generator"

# Huxley Open Source Component Family
pandacluster = require "panda-cluster"    # cluster management
pandahook = require "panda-hook"          # githook management


#===============================================================================
# Helpers
#===============================================================================
# This instantiates a database interface via Pirate.
adapter = Memory.Adapter.make()

# This creates the random authorization token associated with a given user.
make_key = () -> key_forge.randomKey 16, "base64url"

# Temporary measure.  Read in the master SSH public key from a file in this code's
# path.  The key gets placed on every cluster this server creates.
get_master_key = async () -> yield read "#{__dirname}/huxley_master.pub"

#===============================================================================
# Module Definition
#===============================================================================
module.exports = async ->

  clusters = yield adapter.collection "clusters"
  users = yield adapter.collection "users"

  clusters:

    ###
    cluster: cluster_id
      email: String
      url: String
      name: String
    ###

    create: async ({respond, url, data}) ->
      data = yield data
      cluster_id = make_key()
      user = yield users.get data.email

      # Check user authorization.
      #if user && secret_token == user.secret_token
      if true
        # Add cluster to user records.
        cluster_entry =
          email: data.email
          url: cluster_id
          name: data.cluster_name
        cluster_res = yield clusters.put cluster_id, cluster_entry

        # Add Huxley master key to the list of user keys.
        data.public_keys.push yield get_master_key()

        # Create a CoreOS cluster using panda-cluster
        pandacluster.create_cluster data
        respond 201, "", {location: (url "cluster", {cluster_id})}
      else
        respond 401, "invalid email or token"

  cluster:

    # FIXME: pass in secret token in auth header
    delete: async ({respond, match: {path: {cluster_id}}, request: {headers: {authorization}}}) ->
      cluster = yield clusters.get cluster_id
      if cluster
        {email, name} = cluster
        user = yield users.get email
        # FIXME: validate secret token
        #if user && secret_token == user.secret_token
        if user
          request_data =
            aws: user.aws
            cluster_name: name
          clusters.delete cluster_id
          # FIXME: removed yield in clusters.delete
          pandacluster.delete_cluster request_data
          respond 200, "cluster #{name} is being processed for deletion"
        else
          respond 401, "invalid email or token"
      else
        respond 404, "cluster not found"

    get: async ({respond, match: {path: {cluster_id}}, request: {headers: {authorization}}}) ->
      clusters = (yield clusters)
      cluster = (yield clusters.get cluster_id)
      if cluster
        {email} = cluster
        user = yield users.get email
        # FIXME: validate secret token
        #if user && secret_token == user.secret_token
        if user
          request_data =
            aws: user.aws
            cluster_name: cluster.name
          cluster_status = yield pandacluster.get_cluster_status request_data
          respond 200, {cluster_status}
        else
          respond 401, "invalid email or token"
      else
        respond 404, "cluster not found"

  remotes:

    # This function uses panda-hook to push a githook script onto the target cluster's hook server.
    create: async (spec) ->
      {respond, url, data} = spec
      # TODO validation
      pandahook.push yield data
      respond 201, "githook installed."


  remote:

    # This function
    delete: async (spec) ->
      {respond, url, data} = spec
      # TODO validation
      pandahook.destroy spec
      respond 201, "remote repository deleted. git alias removed."

  users:

    ###
    user: email
      public_keys: Array[String]
      key_pair: String
      aws: Object
      email: String
      secret_token: String
    ###

    create: async ({respond, url, data}) ->
      key = make_key()
      data.secret_token = key
      user = yield data
      user.secret_token = key
      yield users.put user.email, user
      respond 201, {user}

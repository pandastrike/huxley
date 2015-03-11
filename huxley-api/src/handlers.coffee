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

  # Database Table Declarations
  #-------------------------------------------------------
  clusters = yield adapter.collection "clusters"
  remotes = yield adapter.collection "remotes"
  #users = yield adapter.collection "users"

  #
  # cluster: cluster_id
  #   name: String
  #
  # remotes: remote_id
  #   hook_address: String
  #   repo_name: String

  #-------------------------------------------------------

  clusters:
    create: async (request) ->
      {respond, data} = request
      data = yield data
      # TODO: validation (see below).

      # Create a record to be stored in the server's database.
      record =
        aws: data.aws
        cluster_name: data.cluster_name
        region: data.region             if data.region?

      # Store the record using a unique token as the key.
      cluster_id = make_key()
      clusters.put cluster_id, record

      # Add Huxley master key to the list of user keys.
      data.public_keys.push yield get_master_key()

      # Create a CoreOS cluster using panda-cluster
      pandacluster.create_cluster data
      respond 201, "Cluster creation underway.", {cluster_id: cluster_id}

      # Related to authorization
      #-----------------------------------------
      # user = yield users.get data.email
      # # Check user authorization.
      # #if user && secret_token == user.secret_token
      # if true
      #   # Add cluster to user records.
      #   cluster_entry =
      #     email: data.email
      #     url: cluster_id
      #     name: data.cluster_name
      #   cluster_res = yield clusters.put cluster_id, cluster_entry
      # else
      #   respond 401, "invalid email or token"

  cluster:
    delete: async (request) ->
      {respond, match: {path: {cluster_id}}} = request
      # TODO: validation (see below).

      # Lookup info about this remote using its ID.
      cluster = yield clusters.get yield cluster_id

      # Use panda-cluster to delete the cluster.
      if cluster?
        pandacluster.delete_cluster cluster
        respond 200, "Cluster deletion underway."
      else
        respond 404, "Unknown cluster ID."


    get: async (request) ->
      {respond, match: {path: {cluster_id}}} = request
      # TODO: validation (see below).

      # Lookup info about this remote using its ID.
      cluster = yield clusters.get yield cluster_id

      # Use panda-cluster to detect cluster status.
      if cluster?
        result = yield pandacluster.get_cluster_status cluster
        if result
          respond 200, {cluster_status: "The cluster is confirmed to be online and ready."}
        else
          respond 200, {cluster_status: "Cluster formation is underway"}
      else
        respond 404, "Unknown cluster ID."


      #========================================
      # This code was part of cluster delete
      #========================================
      # FIXME: pass in secret token in auth header
      # cluster = yield clusters.get cluster_id
      # if cluster
      #   {email, name} = cluster
      #   user = yield users.get email
      #   # FIXME: validate secret token
      #   #if user && secret_token == user.secret_token
      #   if user
      #     request_data =
      #       aws: user.aws
      #       cluster_name: name
      #     clusters.delete cluster_id
      #     # FIXME: removed yield in clusters.delete
      #     pandacluster.delete_cluster request_data
      #     respond 200, "cluster #{name} is being processed for deletion"
      #   else
      #     respond 401, "invalid email or token"
      # else
      #   respond 404, "cluster not found"


    #========================================
    # This code used to be cluster get
    #========================================
    # get: async ({respond, match: {path: {cluster_id}}, request: {headers: {authorization}}}) ->
    #   clusters = (yield clusters)
    #   cluster = (yield clusters.get cluster_id)
    #   if cluster
    #     {email} = cluster
    #     user = yield users.get email
    #     # FIXME: validate secret token
    #     #if user && secret_token == user.secret_token
    #     if user
    #       request_data =
    #         aws: user.aws
    #         cluster_name: cluster.name
    #       cluster_status = yield pandacluster.get_cluster_status request_data
    #       respond 200, {cluster_status}
    #     else
    #       respond 401, "invalid email or token"
    #   else
    #     respond 404, "cluster not found"


  remotes:
    # This function uses panda-hook to push a githook script onto the target cluster's hook server.
    create: async (request) ->
      {respond, data} = request
      data = yield data
      # TODO: validation

      # Create a record to be stored in the server's database.
      address = data.hook_address.split ":"
      record =
        hook_address: address[0]
        hook_port: address[1] || 22
        repo_name: data.repo_name

      # Store the record using a unique token as the key.
      remote_id = make_key()
      remotes.put remote_id, record

      # Access panda-hook to create a githook and place it on the cluster.
      yield pandahook.push data
      respond 201, "githook installed", {remote_id: remote_id}


  remote:
    # This function uses panda-hook to delete a repository on the cluster's hook server.
    delete: async (request) ->
      {respond, match: {path: {remote_id}}} = request
      remote_id = yield remote_id
      # TODO validation

      # Lookup info about this remote using its ID.
      remote = yield remotes.get remote_id

      # Use panda-hook to delete the remote repository.
      console.log remote
      if remote?
        yield pandahook.destroy remote
        respond 200, "remote repository deleted. git alias removed."
      else
        respond 404, "unknown remote repository ID."

  #----------------------------
  # Removed "user" functionality for now
  #----------------------------
  # users:
  #
  #   ###
  #   user: email
  #     public_keys: Array[String]
  #     key_pair: String
  #     aws: Object
  #     email: String
  #     secret_token: String
  #   ###
  #
  #   create: async ({respond, url, data}) ->
  #     key = make_key()
  #     data.secret_token = key
  #     user = yield data
  #     user.secret_token = key
  #     yield users.put user.email, user
  #     respond 201, {user}

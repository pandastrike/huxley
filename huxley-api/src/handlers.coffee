#===============================================================================
# Modules
#===============================================================================
# PandaStrike Libraries
{Memory} = require "pirate"               # database adapter
key_forge = require "key-forge"           # cryptography
{clone, last, read} = require "fairmont"  # utils and functional helper library

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
  profiles = yield adapter.collection "profiles"
  deployments = yield adapter.collection "deployments"

  #
  # cluster: cluster_id
  #   name: StringG
  #   status: String
  #   deployments: [id1, id2, id3]
  #
  #
  # remotes: remote_id
  #   hook_address: String
  #   repo_name: String

  #-------------------------------------------------------

  clusters:
    create: async (request) ->
      {respond, data} = request
      data = yield data

      if (!data.secret_token) || !(yield profiles.get data.secret_token)
        respond 401, "Unknown profile."
      else
        # Create a record to be stored in the server's database.
        record =
          aws: data.aws
          cluster_name: data.cluster_name
          region: data.region             if data.region?

        # Store the record using a unique token as the key.
        cluster_id = make_key()
        clusters.put cluster_id, record

        # Add this cluster to the profile's record.
        profile = yield profiles.get data.secret_token
        profile.clusters[cluster_id] = {name: data.cluster_name, status: "starting"}

        # Add Huxley master key to the list of user keys.
        data.public_keys.push yield get_master_key()

        # Create a CoreOS cluster using panda-cluster
        pandacluster.create_cluster data
        respond 201, "Cluster creation underway.", {cluster_id: cluster_id}


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

  deployments:
    # NOTE: deployments are created automatically when the first status
    # is POSTed. We include this endpoint for completeness's sake
    create: async ({respond, url, data}) ->
      {deployment_id, cluster_id} = yield data
      yield deployments.put deployment_id,
        id: deployment_id
        cluster_id
      respond 200, "Created", location: url "deployment", {deployment_id}

    query: async ({respond, match: {query}}) ->
      # Workaround for pandastrike/pbx#13
      respond 200, JSON.stringify yield deployments.all()

  deployment:
    get: async ({respond, match: {path: {deployment_id}}}) ->
      deployment = yield deployments.get deployment_id
      if deployment?
        # workaround for pandastrike/pirate#23
        deployment = clone deployment
        for service, status of deployment.services
          {status, detail, timestamp} = last status
          deployment.services[service] = {status, detail, timestamp}
        respond 200, deployment
      else
        respond.not_found()

    delete: async ({respond, match: {path: {deployment_id}}}) ->
      deployment = yield deployments.get deployment_id
      if deployment?
        yield deployments.delete deployment_id
        respond 200, "Deleted"
      else
        respond.not_found()

  status:
    post: async ({respond, data}) ->
      {deployment_id, cluster_id, application_id, service} = status = yield data
      deployment = yield deployments.get deployment_id

      # create deployment if not exists
      unless deployment?
        deployment = {id: deployment_id, cluster_id, application_id}

      # add status to appropriate queue
      deployment.services ?= {}
      deployment.services[service] ?= []
      deployment.services[service].push status

      # save changes
      yield deployments.put deployment_id, deployment
      respond 201, "Created" # no url

  #----------------------------
  # Profiles
  #----------------------------

  ###
  profile: email
    config: huxley file object
    secret_token: String
    clusters: {
      id: String
        name: String
      ...
      id: String
        name: String
    }
  ###

  profiles_mock =
    asdf123:
      clusters:
        sometoken:
          name: "fearless-panda"
        anothertoken:
          name: "sparkles"

  clusters_mock =
    sometoken:
      status: "running"
      deployments: ["id1", "id2", "id3"]
    anothertoken:
      status: "failed"
      deployments: ["a", "b", "c"]

  deployments_mock =
    id1:
      id: "id1"
      cluster: "fearless-panda"
      services:
        service_a: [ "starting", "running" ]
        service_b: [ "starting", "running" ] # chronological order
    id2:

  #
  # cluster: cluster_id
  #   name: String
  #   status: String
  #   deployments: [id1, id2, id3]
  #
  #
  # remotes: remote_id
  #   hook_address: String
  #   repo_name: String


  profile:

    # FIXME: how to pass in secret_token? is headers supported yet?
    get: async (spec) ->
      # {respond, request} = spec
      # {headers} = request
      #secret_token = headers.Authorization
      {respond, url, match: {path: {secret_token}}} = spec
      console.log Object.keys spec.match
      console.log spec.match.path
      console.log "****secret token: ", secret_token
      profile = yield profiles.get secret_token
      if profile?
        respond 200, {profile}
      else
        respond 404


  profiles:

    create: async ({respond, url, data}) ->
      {data} = (yield data)
      if yield profiles.get data.email
        respond 403, "Profile already exists"
      else
        # FIXME: deleted public keys cause it was too messy to print
        delete data.config.public_keys
        # FIXME: deleted (old) secret_token stored in config to avoid confusion
        delete data.config.secret_token
        secret_token = make_key()
        profile =
          config: data.config
          secret_token: secret_token
          email: data.email
          clusters: {}
        yield profiles.put secret_token, profile
        console.log "*****all profiles: ", profiles
        respond 201, {profile}

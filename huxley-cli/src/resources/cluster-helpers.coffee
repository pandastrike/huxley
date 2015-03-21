#===============================================================================
# Huxley - Resource "cluster" - Helper Functions
#===============================================================================
# Clusters require some sophisticated configuration.  This file holds some of the
# helper functions to keep the cluster.coffee file clean.
{resolve} = require "path"
{read, async, shuffle, project, collect} = require "fairmont"
{parse} = require "c50n"


# This function selects and returns a random element from an input array.
# TODO: This is a poor implementation because it wastefully shuffles the whole
#       just to select one value.  It was just handy in fairmont...  fix this later.
select_random = (list) ->
  list = shuffle list
  return list[0]


module.exports =

  #------------------------
  # Huxley Cluster Create
  #------------------------
  # Construct an object that will be passed to the Huxley API to used by its panda-cluster library.
  build_create_cluster: async (config, argv) ->
    # Did the user input a cluster name?
    if argv.length == 1
      # The user gave us a name.  Use it.
      cluster_name = argv[0]
    else
      # The user didn't give us anything.  Generate a cluster name from our list of ajectives and nouns.
      {adjectives, nouns} = parse( yield read( resolve( __dirname, "..", "names.cson")))
      cluster_name = "#{select_random(adjectives)}-#{select_random(nouns)}"

    # Return "options" object for panda-cluster's create function.
    return {
      # Required
      aws: config.aws
      key_name: config.aws.key_name
      availability_zone: config.aws.availability_zone
      cluster_name: cluster_name
      public_domain: config.public_domain
      private_domain: "#{cluster_name}.cluster"

      # Optional
      channel: config.channel                   || 'stable'
      cluster_size: config.cluster_size         || 3
      instance_type: config.instance_type       || "m1.medium"
      public_keys: config.public_keys           || []
      region: config.region                     if config.region?
      formation_service_templates: true
      spot_price: config.spot_price             if config.spot_price?
      virtualization: config.virtualization     || "pv"

      tags: [{Key: "role", Value: config.tags}]

      # Huxley Access
      url: config.huxley.url
      secret_token: config.huxley.secret_token
      email: config.huxley.email
    }


  # Check the root level config to make sure what the user's requesting can be done.
  check_create_cluster: async (config, argv) ->
    if config.clusters?
      clusters = collect yield project "name", config.clusters
      if argv[0] in clusters
        message = "There is already a cluster named #{argv[0]} registered with your account \n " +
                  "Please use select another name or use \"huxley cluster delete #{argv[0]}\" to delete the current cluster."
        throw message

  # Update the root level config based on what "huxley cluster create" changes.
  update_create_cluster: async (config, options, api_response) ->
    unless config.data.clusters?
      config.data.clusters = []

    config.data.clusters.push {
      name: options.cluster_name
      domain: options.public_domain
      id: api_response.cluster_id
    }

    yield config.save()



  #------------------------
  # Huxley Cluster Delete
  #------------------------
  # Construct an object that will be passed to the Huxley API to be used by its panda-cluster library.
  build_delete_cluster: async (config, argv) ->
    clusters = collect yield project "name", config.clusters
    index = clusters.indexOf argv[0]

    return {
      cluster_id: config.clusters[index].id
      url: config.huxley.url
      secret_token: config.huxley.secret_token
      email: config.huxley.email
    }


  # Check the application level config to make sure what the user's requesting can be done.
  check_delete_cluster: async (config, argv) ->
    if config.clusters?
      clusters = collect yield project "name", config.clusters
      unless argv[0] in clusters
        throw "Error: The cluster \"#{argv[0]}\" is not registered with your account. Nothing to remove."
    else
      throw "Error: The cluster \"#{argv[0]}\" is not registered with your account. Nothing to remove."


  # Update the application level config based on what "huxley cluster delete" changes.
  update_delete_cluster: async (config, argv) ->
    clusters = collect yield project "name", config.data.clusters
    index = clusters.indexOf argv[0]
    config.data.clusters[index..index] = []

    yield config.save()

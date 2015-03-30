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
  {random, round} = Math
  index = round random() * (list.length - 1)
  return list[index]


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
      region: config.region                     || config.aws.region
      formation_service_templates: true
      spot_price: config.spot_price             if config.spot_price?
      virtualization: config.virtualization     || "pv"

      tags: [{Key: "role", Value: config.tags}]

      # Huxley Access
      url: config.huxley.url
      secret_token: config.huxley.profile.secret_token
    }



  #------------------------
  # Huxley Cluster Delete
  #------------------------
  # Construct an object that will be passed to the Huxley API to be used by its panda-cluster library.
  build_delete_cluster: (config, argv) ->
    return {
      cluster_name: argv[0]
      url: config.huxley.url
      secret_token: config.huxley.profile.secret_token
    }

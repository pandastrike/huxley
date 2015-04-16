#===============================================================================
# Huxley - Resource "cluster" - Helper Functions
#===============================================================================
# Clusters require some sophisticated configuration.  This file holds some of the
# helper functions to keep the cluster.coffee file clean.
{resolve} = require "path"
{read, async} = require "fairmont"
{parse} = require "c50n"


# This function selects and returns a random element from an input array.
select_random = (list) ->
  {random, round} = Math
  index = round random() * (list.length - 1)
  return list[index]


module.exports =

  create:
    # Construct an object that will be passed to the Huxley API to used by its panda-cluster library.
    build: async (config, spec) ->

      # Did the user input a cluster name?
      if spec.first
        # The user gave us a name.  Use it.
        cluster_name = spec.first
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
        huxley:
          url: config.huxley.url
          token: config.huxley.profile.token
      }



  delete:
    # Construct an object that will be passed to the Huxley API to be used by its panda-cluster library.
    build: (config, spec) ->
      return {
        aws: config.aws
        cluster:
          name: spec.first
        huxley:
          url: config.huxley.url
          token: config.huxley.profile.token
      }

  describe:
    # Construct an object that will be passed to the Huxley API to be used by its panda-cluster library.
    build: (config, spec) ->
      throw "Please provide a cluster name." unless spec.first?
      return {
        cluster:
          name: spec.first
        huxley:
          url: config.huxley.url
          token: config.huxley.profile.token
      }

  list:
    # Construct an object that will be passed to the Huxley API to be used by its panda-cluster library.
    build: (config) ->
      return {
        huxley:
          url: config.huxley.url
          token: config.huxley.profile.token
      }

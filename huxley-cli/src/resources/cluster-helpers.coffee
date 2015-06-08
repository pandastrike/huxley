#===============================================================================
# Huxley - Resource "cluster" - Helper Functions
#===============================================================================
# Clusters require some sophisticated configuration.  This file holds some of the
# helper functions to keep the cluster.coffee file clean.
{join} = require "path"
{read, async, shell, empty} = require "fairmont"
Configurator = require "panda-config"

# This function reads the YAML file containing a pool of adjectives and nouns to construct random names.
get_names = async () ->
  configurator = Configurator.make
    format: "yaml"
    extension: ".yaml"
    paths: [ join __dirname, ".." ]

  config = configurator.make name: "names"
  yield config.load()
  return config.data

# This function selects and returns a random element from an input array.
pluck = (list) ->
  {random, round} = Math
  index = round random() * (list.length - 1)
  return list[index]


module.exports =

  create:
    # Construct an object that will be passed to the Huxley API to used by its panda-cluster library.
    build: async (config, spec, answers) ->

      # Using default AWS config?
      {aws} = config
      aws.region = answers.region
      aws.availability_zone = answers.zone
      aws.key_name = answers.key

      # Did the user input a cluster name?
      if spec.first
        name = spec.first # The user gave us a name.  Use it.
      else
        # Generate a cluster name from our list of adjectives and nouns.
        {adjectives, nouns} = yield get_names()
        name = "#{pluck adjectives}-#{pluck nouns}"

      # Return "options" object for panda-cluster's create function.
      return {
        aws: aws
        cluster:
          name: name
          size: answers.size
          type: answers.type
          price: Number(answers.price)
          virtualization: answers.virtualization
          tags: [{Key: "role", Value: answers.tags}]
          zones:
            public:
              name: answers.domain
            private:
              name: "#{name}.cluster"
        coreos:
          channel: answers.channel
        public_keys: config.public_keys  || []
        huxley:
          url: config.huxley.url
          token: config.huxley.profile.token
      }



  delete:
    # Construct an object that will be passed to the Huxley API to be used by its panda-cluster library.
    build: (config, spec) ->
      return {
        cluster:
          name: spec.first
        huxley:
          url: config.huxley.url
          token: config.huxley.profile.token
      }

    # Make changes to the local machine that reflect a change
    cleanup: async ({cluster}) ->
      {name, domain} = cluster

      # Remove the git remote for this cluster. Allowed to fail.
      try
        yield shell "git remote rm #{name}"
      catch error

      # Remove the IP address from "known_hosts"
      try
        hostname = "#{name}.#{domain}"
        text = yield read "#{process.env.HOME}/.ssh/known_hosts"
        hosts = text.split("\n")

        remnants = []
        remnants.push(host) for host in hosts when empty host.match(hostname)
        text = remnants.join("\n")

        yield shell "echo '#{text}' > #{process.env.HOME}/.ssh/known_hosts"
      catch error
        console.log "Unable to edit 'known_hosts'."



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

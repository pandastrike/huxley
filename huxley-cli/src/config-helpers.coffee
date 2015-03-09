#===============================================================================
# Huxley - Configuration Handlers
#===============================================================================
# This file specifies the helper functions that get called whenever a Huxley CLI
# command makes a change to the application's or service's configuration.  There
# are several checks and conditionals that need to happen, so all the clutter is
# gathered here to keep the main "cli.coffee" tidy.
#===============================================================================
# Modules
#===============================================================================
# Core Libraries
{resolve} = require "path"

# Panda Strike Libraries
{map, pluck, remove, read, shuffle} = require "fairmont"
{parse} = require "c50n"

# Third Party Libraries
async = (require "when/generator").lift         # promise library


#===============================================================================
# Helpers
#===============================================================================
# Just to ensure good error handling, catch any errors from these helpers and
# bubble them up through the CLI handlers.
catch_fail = (f) ->
  try
    f()
  catch e
    throw e

# This function selects and returns a random element from an input array.
# TODO: This is a shitty implementation...  fix this later.
select_random = (list) ->
  list = shuffle list
  return list[0]


#===============================================================================
# Module Definition
#===============================================================================
module.exports =

  #------------------------
  # Huxley Cluster Create
  #------------------------
  # Construct an object that will be passed to the Huxley API to used by its panda-cluster library.
  build_create_cluster: async (config, argv) ->
    catch_fail ->
      # Did the user input a cluster name?
      if argv.length == 1
        # The user gave us a name.  Use it.
        cluster_name = argv[0]
      else
        # The user didn't give us anything.  Generate a cluster name from our list of ajectives and nouns.
        {adjectives, nouns} = parse( yield read( resolve( __dirname, "names.cson")))
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
        formation_service_templates:
                config.extra_storage              || true
        spot_price: config.spot_price             if config.spot_price?
        virtualization: config.virtualization     || "pv"

        # Huxley Access
        url: config.huxley.url
        secret_token: config.huxley.secret_token
        email: config.huxley.email
      }


  # Check the root level config to make sure what the user's requesting can be done.
  check_create_cluster: async (config, argv) ->
    catch_fail ->
      if config.clusters?
        clusters = yield map ((x) -> pluck "name", x), config.clusters
        if argv[0] in clusters
          message = "There is already a cluster named #{argv[0]} registered with your account \n " +
                    "Please use select another name or use \"huxley cluster delete #{argv[0]}\" to delete the current cluster."
          throw message

  # Update the root level config based on what "huxley cluster create" changes.
  update_create_cluster: async (config, options, api_response) ->
    catch_fail ->
      unless config.data.clusters?
        config.data.clusters = []

      config.data.clusters.push {
        name: options.cluster_name
        id: api_response.cluster_id
      }

      yield config.save()



  #------------------------
  # Huxley Cluster Delete
  #------------------------
  # Construct an object that will be passed to the Huxley API to be used by its panda-cluster library.
  build_delete_cluster: async (config, argv) ->
    catch_fail ->
      clusters = yield map ((x) -> pluck "name", x), config.clusters
      index = clusters.indexOf argv[0]

      return {
        cluster_id: config.clusters[index].id
        url: config.huxley.url
        secret_token: config.huxley.secret_token
        email: config.huxley.email
      }


  # Check the application level config to make sure what the user's requesting can be done.
  check_delete_cluster: async (config, argv) ->
    catch_fail ->
      if config.clusters?
        clusters = yield map ((x) -> pluck "name", x), config.clusters
        unless argv[0] in clusters
          throw "Error: The cluster \"#{argv[0]}\" is not registered with your account. Nothing to remove."
      else
        throw "Error: The cluster \"#{argv[0]}\" is not registered with your account. Nothing to remove."


  # Update the application level config based on what "huxley cluster delete" changes.
  update_delete_cluster: async (config, argv) ->
    catch_fail ->
      clusters = yield map ((x) -> pluck "name", x), config.data.clusters
      index = clusters.indexOf argv[0]
      config.data.clusters[index..index] = []

      yield config.save()


  #------------------------
  # Huxley Cluster Poll
  #------------------------
  # Construct an object that will be passed to the Huxley API to be used by its panda-cluster library.
  build_poll_cluster: async (config, argv) ->
    catch_fail ->
      clusters = yield map ((x) -> pluck "name", x), config.clusters
      index = clusters.indexOf argv[0]

      return {
        cluster_id: config.clusters[index].id
        url: config.huxley.url
        secret_token: config.huxley.secret_token
        email: config.huxley.email
      }


  # Check the application level config to make sure what the user's requesting can be done.
  check_poll_cluster: async (config, argv) ->
    catch_fail ->
      if config.clusters?
        clusters = yield map ((x) -> pluck "name", x), config.clusters
        unless argv[0] in clusters
          throw "Error: The cluster \"#{argv[0]}\" is not registered with your account. Nothing to poll."
      else
        throw "Error: The cluster \"#{argv[0]}\" is not registered with your account. Nothing to poll."


  #------------------------
  # Huxley Remote Add
  #------------------------
  # Construct an object that will be passed to the Huxley API to used by its panda-hook library.
  build_add_remote: async (config, argv) ->
    catch_fail ->
      return yield {
        cluster_address: "core@#{argv[0]}.#{config.public_domain}"
        repo_name: config.app_name
        hook_address: "root@#{argv[0]}.#{config.public_domain}:3000"
        url: config.huxley.url
        secret_token: config.huxley.secret_token
        email: config.huxley.email
      }

  # Check the application level config to make sure what the user's requesting can be done.
  check_add_remote: async (config, argv) ->
    catch_fail ->
      if config.remotes?
        remotes = yield map ((x) -> pluck "name", x), config.remotes
        if argv[0] in remotes
          message = "There is already a remote named #{argv[0]} registered with this application. \n " +
                    "Please use \"huxley remote rm #{argv[0]}\" to delete and try again."
          throw message


  # Update the application level config based on what "huxley remote add" changes.
  update_add_remote: async (config, argv, api_response) ->
    catch_fail ->
      unless config.data.remotes?
        config.data.remotes = []

      config.data.remotes.push {
        name: argv[0]
        id: api_response.remote_id
      }

      yield config.save()

  #------------------------
  # Huxley Remote Remove
  #------------------------
  # Construct an object that will be passed to the Huxley API to used by its panda-hook library.
  build_rm_remote: async (config, argv) ->
    catch_fail ->
      remotes = yield map ((x) -> pluck "name", x), config.remotes
      index = remotes.indexOf argv[0]

      return {
        remote_id: config.remotes[index].id
        url: config.huxley.url
        secret_token: config.huxley.secret_token
        email: config.huxley.email
      }


  # Check the application level config to make sure what the user's requesting can be done.
  check_rm_remote: async (config, argv) ->
    catch_fail ->
      if config.remotes?
        remotes = yield map ((x) -> pluck "name", x), config.remotes
        unless argv[0] in remotes
          throw "Error: The remote #{argv[0]} is not registered with your account. Nothing to remove."
      else
        throw "Error: The remote #{argv[0]} is not registered with your account. Nothing to remove."

  # Update the application level config based on what "huxley remote rm" changes.
  update_rm_remote: async (config, argv) ->
    catch_fail ->
      remotes = yield map ((x) -> pluck "name", x), config.data.remotes
      index = remotes.indexOf argv[0]
      config.data.remotes[index..index] = []

      yield config.save()

  #------------------------
  # Huxley Remote Passive
  #------------------------
  # For now, when Huxley adds "passive" repositories to the cluster, it doesn't get routed though
  # the API server.  For now, we just execute a series of shell commands.
  run_passive_remote: async (config, argv) ->
    catch_fail ->
      # Shell to the specified cluster and create a bare repo.  Overwrite anything in our path.
      command =
        "ssh -A -o \"StrictHostKeyChecking no\"  -o \"UserKnownHostsFile=/dev/null\" " +
        "-p 3000 root@#{argv[0]}.#{config.public_domain} << EOF\n" +
        "cd /root/passive \n " +
        "if [ -d #{config.repo_name}.git ]; then \n " +
        "  rm -rf #{config.repo_name}.git \n" +
        "fi \n " +
        "mkdir #{config.repo_name}.git \n " +
        "cd #{config.repo_name}.git \n " +
        "/usr/bin/git init --bare \n " +
        "EOF"

      yield shell command

      # Next, we will add this repository to the user's git remotes.  Allow "remote rm" to fail if neccessary, so do it separately.
      yield force shell, "git remote rm  #{argv[0]}"
      yield shell "git remote add #{argv[0]} ssh://root@#{argv[0]}.#{config.public_domain}:3000/root/passive/#{config.repo_name}.git"

      # Because this does not cause a deployment, we can actually go ahead and push the
      # local repository to the passive remote. Initialize a git repo in the executable
      # path, commit everything, and push.
      command =
        "cd #{process.cwd()} &&" +
        "git init; " +
        "git add -A; "+
        "git commit -m 'Repo commited by Huxley to place on cluster.'; " +
        "git push #{config.repo_name} master"

      yield shell command

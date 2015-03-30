#===============================================================================
# Huxley - Resource "remote" - Helper Functions
#===============================================================================
# Adding remote repositories onto a Huxley cluster requires some sophisticated
# configuration.  This file holds some of the helper functions to keep the remote.coffee file clean.
{resolve} = require "path"
{async, project, shell, property, collect} = require "fairmont"
{force, where} = require "../helpers"
api = require "../api-interface"

module.exports =
  #------------------------
  # Huxley Remote Add
  #------------------------
  # Construct an object that will be passed to the Huxley API to used by its panda-hook library.
  build_add_remote: (config, argv, cluster) ->
    {cluster_id} = cluster
    domain = cluster.cluster.public_domain

    return {
      cluster_id: cluster_id
      public_domain: domain
      cluster_address: "core@#{argv[0]}.#{domain}"
      repo_name: config.app_name
      hook_address: "root@#{argv[0]}.#{domain}:3000"
      url: config.huxley.url
      secret_token: config.huxley.profile.secret_token
    }

  # Check to see if this remote repository can be created.
  check_add_remote: async (config, argv) ->
    # Build a data object to query the API's database for active clusters.
    options =
      url: config.huxley.url
      secret_token: config.huxley.profile.secret_token
      cluster_name: argv[0]

    response = yield api.get_cluster options
    if response.cluster.status != "online"
      throw "The cluster is not ready to accept a remote repository."

    # TODO: Check to see if there is an active "remote" on the cluster already.

    # Return data about the cluster
    return response



  #------------------------
  # Huxley Remote Remove
  #------------------------
  # Construct an object that will be passed to the Huxley API to used by its panda-hook library.
  build_rm_remote: async (config, cluster) ->
    {cluster_id} = cluster

    return {
      cluster_id: cluster_id
      url: config.huxley.url
      secret_token: config.huxley.profile.secret_token
    }


  # Check the application level config to make sure what the user's requesting can be done.
  check_rm_remote: async (config, argv) ->
    # Build a data object to query the API's database for active clusters.
    options =
      url: config.huxley.url
      secret_token: config.huxley.profile.secret_token
      cluster_name: argv[0]

    response = yield api.get_cluster options
    if response.cluster.status != "online"
      throw "The cluster is not ready.  Nothing to remove."

    # TODO: Check to see that there is a remote on the cluster in question.
    # if config.remotes?
    #   remotes = collect yield project "name", config.remotes
    #   unless argv[0] in remotes
    #     throw "Error: The remote #{argv[0]} is not registered with your account. Nothing to remove."
    # else
    #   throw "Error: The remote #{argv[0]} is not registered with your account. Nothing to remove."

    return response



  #------------------------
  # Huxley Remote Passive
  #------------------------
  # For now, when Huxley adds "passive" repositories to the cluster, it doesn't get routed though
  # the API server.  For now, we just execute a series of shell commands.
  run_passive_remote: async (config, argv) ->
    # Build a data object to query the API's database for active clusters.
    options =
      url: config.huxley.url
      secret_token: config.huxley.profile.secret_token
      cluster_name: argv[0]

    response = yield api.get_cluster options
    if response.cluster.status != "online"
      throw "The cluster is not ready to accept a remote repository."

    domain = response.cluster.public_domain

    # Shell to the specified cluster and create a bare repo.  Overwrite anything in our path.
    command =
      "ssh -A -o \"StrictHostKeyChecking no\"  -o \"UserKnownHostsFile=/dev/null\" " +
      "-p 3000 root@#{argv[0]}.#{domain} << EOF\n" +
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
    yield shell "git remote add #{argv[0]} ssh://root@#{argv[0]}.#{domain}:3000/root/passive/#{config.repo_name}.git"

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

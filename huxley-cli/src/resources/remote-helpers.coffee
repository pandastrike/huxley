#===============================================================================
# Huxley - Resource "remote" - Helper Functions
#===============================================================================
# Adding remote repositories onto a Huxley cluster requires some sophisticated
# configuration.  This file holds helper functions to stay organized.
{resolve, join} = require "path"
{async, project, shell, property, collect} = require "fairmont"
{force, where} = require "../helpers"
cluster = (require "../api-interface").cluster

# Check the API server to see if a specified cluster is online and ready.
is_ready = async (config, spec) ->
  # Build a data object to query the API's database for active clusters.
  return yield cluster.get
    cluster:
      name: spec.first
    huxley:
      url: config.huxley.url
      token: config.huxley.profile.token


module.exports =

  create:
    # Construct an object that will be passed to the Huxley API.
    build: (config, spec, cluster) ->
      {id, cluster} = cluster

      return {
        cluster:
          id: id
          name: spec.first
          address: "core@#{spec.first}.#{cluster.domain}"
        app:
          name: config.app_name
          domain: cluster.domain
        hook:
          address: "root@#{spec.first}.#{cluster.domain}:3000"
        huxley:
          url: config.huxley.url
          token: config.huxley.profile.token
      }

    # Check to see if this remote repository can be created.
    check: async (config, spec) ->
      throw "Please provide a cluster name" unless spec.first

      response = yield is_ready(config, spec)
      if response.cluster.status != "online"
        throw "That cluster is not ready to accept a remote repository."

      # TODO: Check to see if there is an active "remote" on the cluster already.
      # Return data about the cluster
      return response

    # Complete additional setup, here and on the hook server.
    setup: async (options, config) ->
      # Add a "git remote" alias. The first command is allowed to fail.
      yield force shell, "git remote rm #{options.cluster.name}"
      yield shell "git remote add #{options.cluster.name} " +
        "ssh://#{options.hook.address}/root/repos/#{options.app.name}.git"

      # Transport files and directories listed in huxley.yaml to the hook server.
      {app, cluster} = options
      {files} = config
      if files && files != []
        # Tar every file and directory listed in "files" of huxley.yaml...
        tar = "tar -zcf - "
        tar += "#{file} " for file in files
        # ...and pipe the output to the hook server over SSH.
        yield shell tar + " | " +
          "ssh -A -o StrictHostKeyChecking=no " +
          "-o UserKnownHostsFile=/dev/null " +
          "-p 3000 root@#{cluster.name}.#{app.domain}  \"" +
          "cat > files/#{app.name}.tar.gz \""

        # Commit what we've just added to the "files" directory.
        yield shell "ssh -A -o StrictHostKeyChecking=no " +
          " -o UserKnownHostsFile=/dev/null " +
          "-p 3000 root@#{cluster.name}.#{app.domain} << EOF \n" +
          "cd files \n" +
          "git config --global user.email 'huxley@pandastrike.com' \n" +
          "git config --global user.name 'huxley-client' \n" +
          "git add -A \n" +
          "git commit -m 'Adding extra data from #{app.name}.' \n" +
          "EOF"

  delete:
    # Construct an object that will be passed to the Huxley API to used by its panda-hook library.
    build: (config, cluster) ->
      {cluster_id} = cluster

      return {
        cluster:
          id: cluster_id
        app:
          name: config.app_name
        huxley:
          url: config.huxley.url
          token: config.huxley.profile.token
      }


    # Check the application level config to make sure what the user's requesting can be done.
    check: async (config, spec) ->
      response = yield is_ready(config, spec)
      if response.cluster.status != "online"
        throw "The cluster is not ready.  Nothing to remove."

      # TODO: Check to see that there is a remote on the cluster in question.
      # if config.remotes?
      #   remotes = collect yield project "name", config.remotes
      #   unless spec.first in remotes
      #     throw "Error: The remote #{spec.first} is not registered with your account. Nothing to remove."
      # else
      #   throw "Error: The remote #{spec.first} is not registered with your account. Nothing to remove."

      return response



  passive:
    # For now, when Huxley adds "passive" repositories to the cluster, it doesn't get routed though
    # the API server.  For now, we just execute a series of shell commands.
    run: async (config, spec) ->
      response = yield is_ready(config, spec)
      unless response.cluster.status != "online"
        throw "The cluster is not ready to accept a remote repository."

      domain = response.cluster.domain

      # Shell to the specified cluster and create a bare repo.  Overwrite anything in our path.
      command =
        "ssh -A -o \"StrictHostKeyChecking no\"  -o \"UserKnownHostsFile=/dev/null\" " +
        "-p 3000 root@#{spec.first}.#{domain} << EOF\n" +
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
      yield force shell, "git remote rm  #{spec.first}"
      yield shell "git remote add #{spec.first} ssh://root@#{spec.first}.#{domain}:3000/root/passive/#{config.repo_name}.git"

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

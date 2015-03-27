#===============================================================================
# Huxley - Resource "cluster"
#===============================================================================
# Clusters are the foundation of Huxley's deployment model.  This file contains
# functions that configure their creation and deletion.
{async, usage, merge} = require "fairmont"
{pull_configuration} = require "../helpers"
{interview} = require "../interview"
api = require "../api-interface"

{build_create_cluster, check_create_cluster, update_create_cluster,
 build_delete_cluster, check_delete_cluster, update_delete_cluster} = require "./cluster-helpers"
#---------------------
# Exposed Methods
#---------------------
module.exports =
  # This function prepares the "options" object to ask the API server to create a
  # CoreOS cluster using your AWS credentials.
  create_cluster: async (argv) ->
    # Detect if we should provide a help blurb.
    if argv[0] == "help" || argv[0] == "-h" || argv[0] == "--help"
      yield usage "cluster_create"

    # Start by reading configuration data from the local config files.
    {config, home_config} = yield pull_configuration()

    # Begin interview
    {questions} = require "../interviews/cluster-create.coffee"
    answers = yield interview questions config
    config = merge config, answers

    # Check to see if this cluster has already been registered in the API.
    yield check_create_cluster config, argv

    # Now use this raw configuration as context to build an "options" object for panda-hook.
    options = yield build_create_cluster config, argv

    # With our object built, call the Huxley API.
    response = yield api.create_cluster options

    # Save the cluster ID to the root-level configuration.
    yield update_create_cluster home_config, options, response


  # This function prepares the "options" object to ask the API server to delete a
  # CoreOS cluster using your AWS credentials.
  delete_cluster: async (argv) ->
    # Detect if we should provide a help blurb.
    if argv.length == 0 || argv[0] == "help" || argv[0] == "-h" || argv[0] == "--help"
      yield usage "cluster_delete"

    # Start by reading configuration data from the local config files.
    {config, home_config} = yield pull_configuration()

    # Check to see if this cluster is registered in the API. We cannot delete what does not exist.
    yield check_delete_cluster config, argv

    # Now use this raw configuration as context to build an "options" object for panda-cluster.
    options = yield build_delete_cluster config, argv

    # With our object built, call the Huxley API.
    yield api.delete_cluster options

    # Save the deletion to the root-level configuration.
    yield update_delete_cluster home_config, argv

  describe_cluster: async (argv) ->
    # Detect if we should provide a help blurb.
    if argv.length == 0 || argv[0] == "help" || argv[0] == "-h" || argv[0] == "--help"
      yield usage "cluster_delete"

    # Start by reading configuration data from the local config files.
    {config, home_config} = yield pull_configuration()

    # Check to see if this cluster is registered in the API. We cannot delete what does not exist.
    yield check_delete_cluster config, argv

    # Now use this raw configuration as context to build an "options" object for panda-cluster.
    options = yield build_delete_cluster config, argv

    # With our object built, call the Huxley API.
    # FIXME: which one?  poll_cluster only returns when successful, not constant status
    yield api.poll_cluster options
    yield api.get_cluster_status options

  list_clusters: async (argv) ->
    # Start by reading configuration data from the local config files.
    {config, home_config} = yield pull_configuration()

    cluster_name = argv[2]

    # With our object built, call the Huxley API.
    profile = yield api.get_profile {config, home_config}

    cluster_id = null
    for id, name of profile.clusters
      if cluster_name == name
        cluster_id = id
    if cluster_id == null
      console.log "Error: cluster #{cluster_name} not found."

    yield api.get_cluster_status {cluster_id, config, home_config}

    console.log profile.clusters

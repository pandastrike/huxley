#===============================================================================
# Huxley - Resource "cluster"
#===============================================================================
# Clusters are the foundation of Huxley's deployment model.  This file contains
# functions that configure their creation and deletion.
{async, merge} = require "fairmont"
{usage, pull_configuration} = require "../helpers"
{interview} = require "../interview"
api = require "../api-interface"

{build_create_cluster, build_delete_cluster} = require "./cluster-helpers"
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

    # Now use the interview and raw configuration as context to build an "options" object for panda-hook.
    options = yield build_create_cluster config, argv

    # With our object built, call the Huxley API.
    response = yield api.create_cluster options



  # This function prepares the "options" object to ask the API server to delete a
  # CoreOS cluster using your AWS credentials.
  delete_cluster: async (argv) ->
    # Detect if we should provide a help blurb.
    if argv.length == 0 || argv[0] == "help" || argv[0] == "-h" || argv[0] == "--help"
      yield usage "cluster_delete"

    # Start by reading configuration data from the local config files.
    {config, home_config} = yield pull_configuration()

    # Use this raw configuration as context to build an "options" object for panda-cluster.
    options = build_delete_cluster config, argv

    # With our object built, call the Huxley API.
    yield api.delete_cluster options

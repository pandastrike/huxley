#===============================================================================
# Huxley API - Database
#===============================================================================
# This file contains the code that manages access to the API's database.  We make
# use of the in-house library "Pirate", which serves as a generalized adapter for
# any database patterened as a key-value store.
{Memory} = require "pirate"  # database adapter
{async} = require "fairmont" # utility library

module.exports =

  initialize_database: async () ->
    # This instantiates a database interface via Pirate.
    adapter = Memory.Adapter.make()

    # Database Collection Declarations
    return {
      clusters: yield adapter.collection "clusters"
      remotes: yield adapter.collection "remotes"
      profiles: yield adapter.collection "profiles"
      deployments: yield adapter.collection "deployments"
    }

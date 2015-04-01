#===============================================================================
# Huxley API - Database
#===============================================================================
# This file contains the code that manages access to the API's database.  We make
# use of the in-house library "Pirate", which serves as a generalized adapter for
# any database patterened as a key-value store.
{Memory} = require "pirate"  # database adapter
{async, md5} = require "fairmont" # utility library

# Until we get "pending" folded properly into the database, this class will serve
# as a rough adapter for the collection.
class Pending
  constructor: (@data) ->

  put: (token, hash, description) ->
    unless @data[token]?
      @data[token] = {}

    hash = md5 description
    @data[token][hash] = description

  get_all: (token) ->
    if @data[token]?
      return @data[token]
    else
      return {}
      
  delete: (token, hash) ->
    delete @data[token][hash] if @data[token][hash]?



module.exports =

  initialize: async () ->
    # This instantiates a database interface via Pirate.
    adapter = Memory.Adapter.make()

    # Database Collection Declarations
    return {
      clusters: yield adapter.collection "clusters"
      deployments: yield adapter.collection "deployments"
      profiles: yield adapter.collection "profiles"
      remotes: yield adapter.collection "remotes"

      # TODO: possibly store in redis using {token}-pending collection
      # and hash as the key, pending.put hash, description
      pending: new Pending {}
    }

# Until we get "pending" folded properly into the database, this class will serve
# as a rough adapter for the collection.

# TODO: possibly store in redis using {token}-pending collection
# and hash as the key, pending.put hash, description
module.exports = class Pending
  constructor: () ->
    @data = {}

  delete: (token, hash) ->
    delete @data[token].last    if @data[token].last == hash
    delete @data[token][hash]   if @data[token][hash]

  list: (token) ->
    if @data[token]
      return @data[token]
    else
      return {}

  put: (token, hash, status, command) ->
    unless @data[token]
      @data[token] = {}

    if @data[token][hash]
      @data[token][hash].status = status
    else
      throw "No command specified for new Pending record." if !command
      @data[token][hash] = {command, status}
      @data[token].last = hash

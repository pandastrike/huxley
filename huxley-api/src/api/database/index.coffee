#===============================================================================
# Huxley API - Database
#===============================================================================
# This file contains the code that manages access to the API's database.  We make
# use of the in-house library "Pirate", which serves as a generalized adapter for
# any database patterened as a key-value store.
#{Memory} = require "pirate"  # database adapter
{Redis} = require "pirate"  # database adapter
{async} = require "fairmont" # utility library

module.exports =
  initialize: require "./intialize"
  lookup: require "./lookup"
  remove: require "./remove"

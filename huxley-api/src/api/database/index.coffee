#===============================================================================
# Huxley API - Database
#===============================================================================
# This file contains the code that manages access to the API's database.  We make
# use of the in-house library "Pirate", which serves as a generalized adapter for
# any database patterened as a key-value store.

module.exports =
  initialize: require "./initialize"

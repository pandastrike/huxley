#===============================================================================
# Huxley API - Handlers - Profile
#===============================================================================
# This file contains API handler functions for the single resource "profile".

{async} = require "fairmont"
{make_key} = require "./helpers"

module.exports = (db) ->

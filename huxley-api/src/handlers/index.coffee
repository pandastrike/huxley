#===============================================================================
# Huxley API - Handlers - Main
#===============================================================================
# This file contains the full assembly of Huxley API handlers.  Each resource
# gets its own handler module to keep things tidy.  We also initialize the
# database adapter (via Pirate) here and pass the resulting object into
# each handler.

{async, call, clone, last, read} = require "fairmont"  # utility library

# Database
database = require "../database"


# Exposed Methods
module.exports = async () ->

  # Intialize the API database
  db = yield database.initialize()

  # Pull in the resource handlers.
  clusters: (require "./clusters")(db)
  cluster:  (require "./cluster")(db)

  deployments: (require "./deployments")(db)
  deployment:  (require "./deployment")(db)

  pending: (require "./pending")(db)

  profiles: (require "./profiles")(db)
  profile: (require "./profile")(db)

  remotes: (require "./remotes")(db)
  remote: (require "./remote")(db)

  status: (require "./status")(db)

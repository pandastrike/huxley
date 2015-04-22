#===============================================================================
# Huxley - Resource "version"
#===============================================================================
# We offer versioning data to the user when requested. This files contains the code to deliver that.
{join} = require "path"
{async, read} = require "fairmont"

module.exports =
  # Deliver version information about the current version of the Huxley CLI.
  version: async () ->
    data = JSON.parse yield read join __dirname, "..", "..", "package.json"
    return "Huxley Version #{data.version}"

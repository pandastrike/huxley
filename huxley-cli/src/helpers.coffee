#===============================================================================
# Huxley - CLI Helpers
#===============================================================================
# This file specifies some handy helper methods.
{resolve, join} = require "path"
{async, read, merge, exists, mkdir, has, deep_equal} = require "fairmont"
Configurator = require "panda-config"


#--------------------
# Exposed Methods
#--------------------
module.exports =

  # Prepare a basic error object to return to the UI.
  build_error: (message, value) ->
    return {
      message: message
      value: value
    }

  # Output an Info Blurb and optional message.
  usage: async (entry, message) ->
    docs = yield read( resolve( __dirname, "..", "docs", entry ) )
    if message?
      throw "#{message}\n" + docs
    else
      throw docs

  # Sometimes we don't care if a promise is rejected, we just need to wait for it to be done one way
  # or another.  This function accepts an input promise but always resolves.
  force: async (f, args...) ->
    try
      yield f args...
    catch e
      null

  # Make a directory at the specified path, but throw an exception if that directory already exists.
  safe_mkdir: async (path, mode) ->
    unless yield exists path
      mode ||= "0777"
      yield mkdir mode, path
    else
      throw "Error: #{path} already exists. \n"


  # In Huxley, configuration data is stored in multiple places.  This function focuses on
  # two levels of configuartion.
  # (1) The first is the user's home configuration, located in the huxley dotfile
  #     within their $HOME directory (holds persistent data attached to their account).
  # (2) The second is the application-level configuration, located in the repo's huxley
  #     manifest file.  TODO: Currently, we only look in the execution path, so we require the
  #     CLI  to be run in the repo's root directory.  This should use an env variable like Node and git.
  pull_configuration: async () ->
    if yield exists join process.env.HOME, ".huxley"
      # Load the configuration from the $HOME directory.
      constructor = Configurator.make
        prefix: "."
        format: "yaml"
        paths: [ process.env.HOME ]

      home_config = constructor.make name: "huxley"
      yield home_config.load()
    else
      throw "You must establish a dotfile configuration in your $HOME directory, ~/.huxley"

    if yield exists join process.cwd(), "huxley.yaml"
      # Load the application level configuration.
      constructor = Configurator.make
        extension: ".yaml"
        format: "yaml"
        paths: [ process.cwd() ]

      app_config = constructor.make name: "huxley"
      yield app_config.load()

    # Create an object that is the union of the two configurations.  Huxley observes
    # configuration scope, so application configuration will override values set in the home-configuration.
    if app_config?
      config = merge home_config.data, app_config.data
    else
      config = home_config.data

    # Return an object we can use to make requests, but also return the panda-config instances
    # in case we need to save something.
    return {
      config: config
      home_config: home_config
      app_config: app_config    if app_config?
    }

  # Nifty function that returns an array of objects when given an array of
  # objects and an object subset to search for.
  where: async (array, query) ->
    final = []

    for obj in array
      count = 0
      for key of query
        break unless yield has key, obj
        break unless yield deep_equal obj[key], query[key]
        count++

      final.push obj  if count == Object.keys(query).length

    return final

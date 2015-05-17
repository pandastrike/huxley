#===============================================================================
# Huxley - Resource "init"
#===============================================================================
# init prepares a repository to be deployed with Huxley.  It establishes a launch
# directory and a huxley manifest file.

{join} = require "path"
{safe_mkdir} = require "../helpers"
{async, exists, shell} = require "fairmont"

{save_interview} = require "../interview"

#-------------------
# Exposed Methods
#-------------------
module.exports =

  # Initialize repository to be deployed by Huxley.
  init: async () ->
    # Create Launch directory.
    yield safe_mkdir join process.cwd(), "launch"

    # Create default huxley.yaml
    if yield exists (join process.cwd(), "huxley.yaml")
      throw "Error: \"huxley.yaml\" already exists. \n"
    else
      # panda-config does not support reading empty files...
      yield shell "echo 'app_name: foo' > huxley.yaml"

      # The repository's name is the application name.
      yield save_interview
        answers: {app_name: process.cwd().split("/").pop()}
        write_path: process.cwd()
        write_filename: "huxley"

      return "Huxley deployment initialized."

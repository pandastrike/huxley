#=================================
# Modules
#=================================
# Base
{readFile, writeFile} = require "fs"
{resolve} = require "path"

# Third Party
{parse} = require "c50n"      # CSON parsing
{render} = require "mustache" # Awesome templating

# When Library
{promise, lift} = require "when"
{liftAll} = require "when/node"
node_lift = (require "when/node").lift
async = (require "when/generator").lift


#==================
# Helper Functions
#==================

# This wraps Node's irregular, asynchronous readFile in a promise.
read_file = (path) ->
  promise (resolve, reject) ->
    readFile path, "utf-8", (error, data) ->
      if data?
        resolve data
      else
        resolve error


#=====================
# Module Definition
#=====================
module.exports =
  read_file: read_file

  # This renders a template that is stored in a local file.
  render_template: async (template_name, input_values, template_path, defaults_path) ->
    try
      # Grab the contents of the template file and this template's defaults.
      template = yield read_file( resolve( template_path))
      if defaults_path?
        data = parse( yield read_file( resolve( defaults_path)))[template_name]
      else
        data = {}

      # We're starting with all default values, and then we insert any explicit configuration input.
      data[key] = input_values[key]   for key of input_values

      # Render the template and return the resulting string.
      return render template, data

    catch error
      return error

  # This is a very cut-and-dry rendering function.  For templates that are not as crazy as the service files.
  simple_render: async (input, template_path) ->
    try
      template = yield read_file( resolve( template_path))
      return render template, input
    catch error
      return error

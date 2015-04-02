#===============================================================================
# Huxley - Resource "mixin"
#===============================================================================
# mixins are launch descriptions used to deploy your app.  Huxley comes with templates
# to anticipate basic launch configurations.

{join} = require "path"
{async, exists, shell} = require "fairmont"
{interview, save_interview, save_mixin_interview} = require "../interview"
{safe_mkdir} = require "../helpers"

#-------------------
# Exposed Methods
#-------------------
module.exports =

  # initialize mixin folders in the user's repository, copy over templates
  create: async (spec) ->
    if spec.first then component_name = spec.first else throw "Error: Please specify a mixin."

    # Begin interview
    try
      {questions} = (require "../interviews/mixins/#{component_name}")
      answers = yield interview questions()
      {service_name} = answers
    catch error
      throw "Error: Invalid mixin specified."

    # Add mixin to launch directory if it doesn't already exist.
    template_dir = join __dirname, "../../templates", component_name
    mixin_dir = join process.cwd(), "launch", service_name
    yield safe_mkdir mixin_dir
    yield shell "cp #{join template_dir, "Dockerfile.template"}                #{join mixin_dir, "Dockerfile.template"}"
    yield shell "cp #{join template_dir, "#{component_name}.service.template"} #{join mixin_dir, "#{service_name}.service.template"}"
    yield shell "cp #{join template_dir, "#{component_name}.yaml"}             #{join mixin_dir, "#{service_name}.yaml"}"

    # Write the service configuration to file (in mixin directory).
    delete answers.service_name
    yield save_interview
      answers: answers
      write_path: join process.cwd(), "launch", service_name
      write_filename: service_name

    # Write the service configuration to file (in huxley.yaml).  TODO: remove need for this.
    yield save_mixin_interview
      answers: answers
      service_name: service_name
      write_path: process.cwd()
      write_filename: "huxley"

    return "Added a \"#{component_name}\" mixin named \"#{service_name}\" to your repository."

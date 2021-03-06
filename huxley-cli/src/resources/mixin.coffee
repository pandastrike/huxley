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
    if spec.first then mixin = spec.first else throw "Error: Please specify a mixin."

    # Begin interview
    try
      {questions} = (require "../interviews/mixin/#{mixin}")
      answers = yield interview questions()
      {name, exclusions, production} = answers
    catch error
      throw "Error: Invalid mixin specified."

    # Process exclusion variable.
    answers.exclusions = []
    if !(/^\s*$/.test(exclusions))
      list = exclusions.split /\s*,\s*/
      answers.exclusions.push(item) for item in list

    # If the mixin is named "www", provide additional routing via a URL that does not start with "www".
    # Example domain.com routes to www.domain.com
    if production && (name == "www")
      answers.www_redirect = true
    else
      answers.www_redirect = false

    # Add mixin to launch directory if it doesn't already exist.
    template_dir = join __dirname, "../../templates", mixin
    mixin_dir = join process.cwd(), "launch", name
    yield safe_mkdir mixin_dir
    yield shell "cp #{join template_dir, "Dockerfile.template"}       #{join mixin_dir, "Dockerfile.template"}"
    yield shell "cp #{join template_dir, "#{mixin}.service.template"} #{join mixin_dir, "#{name}.service.template"}"
    yield shell "cp #{join template_dir, "#{mixin}.yaml"}             #{join mixin_dir, "#{name}.yaml"}"

    # Write the service configuration to file (in mixin directory).
    delete answers.name
    yield save_interview
      answers: answers
      write_path: join process.cwd(), "launch", name
      write_filename: name

    return "Added a \"#{mixin}\" mixin named \"#{name}\" to your repository."

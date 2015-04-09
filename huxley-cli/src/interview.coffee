#===============================================================================
# Huxley - CLI Interviewer
#===============================================================================
# The Huxley CLI relies on an interviewer to collect configuration details from
# the user via prompts.  We wrap the aptly named library "prompt" to achieve this, haha.
Configurator = require "panda-config"
{async, merge} = require "fairmont"
prompt = require "prompt"
{promise} = require "when"

#--------------------
# Exposed Methods
#--------------------
module.exports =

  # Initialize the interviewer.  Remove the default settings, start `prompt`
  setup_interview: () ->
    prompt.message = ""
    prompt.delimiter = ""
    prompt.start()

  # Execute the interview prompt.  We wrap prompt's execution in a promise so we may use ES6 syntax.
  interview: (questions) ->
    promise (resolve, reject) ->
      prompt.get questions, (error, answers) ->
        if error?
          reject error
        else
          resolve answers

  # Write the configuration gathered by the interview to file.
  save_interview: async ({answers, write_path, write_filename}) ->
    configurator = Configurator.make
      paths: [ write_path ]
      extension: ".yaml"
    configuration = configurator.make {name: write_filename}
    yield configuration.load()
    # Merge arguments are added from left to right. The right-most arg will override all previous
    configuration.data = yield merge configuration.data, answers
    yield configuration.save()

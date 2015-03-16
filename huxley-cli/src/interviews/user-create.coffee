#{lift} = (require "when/callbacks")
#{call} = require "when/generator"
#async = (require "when/generator").lift
#
#Configurator = require "panda-config"
#
#call ->
#  configurator = Configurator.make
#    paths: [ process.env.HOME ]
#    prefix: "."
#  configuration = configurator.make name: "huxley"
#  yield configuration.load()
#  {aws: {email}} = configuration.data

module.exports =

  # TODO: if we store email in dotfile, consider defaulting
  # object, not function
  questions:
    [
      name: "email"
      description: "Email?"
      required: true
      #default: email
    ]

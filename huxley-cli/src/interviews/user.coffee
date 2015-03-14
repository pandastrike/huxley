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

  # FIXME: missing public_keys, aws_id, aws_key
  # object, not function

  questions:
    create:
      [
        name: "email"
        description: "Email?"
        required: true
        #default: email
      ]
    delete:
      [
        name: "email"
        description: "Email?"
        required: true
        #default: email
      ]

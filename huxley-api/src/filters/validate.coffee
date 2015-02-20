async = (require "when/generator").lift
module.exports = (handler) ->
  async (context) ->
    (yield handler context) if (yield context.validate())

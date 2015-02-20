{resolve} = require "when"
async = (require "when/generator").lift
JSCK = require("jsck").draft4
Context = require "./context"
classifier = require "./classifier"

module.exports = async (api, initialize) ->

    # TODO: move classification into the context? con: outside of
    # url generation, the context class knows nothing of PBX
    classify = classifier api

    handlers = (yield (resolve initialize(api)))

    if api.resources.description?
      handlers.description ?=
        get: (context) ->
          context.respond 200, api

    api.schema.validate = do ->
      jsck = (new JSCK api.schema )
      (type, object) ->
        jsck.validator(mediaType: type).validate(object)

    async (request, response) ->
      try
        context = Context.make {request, response, api}
        try
          context.match = classify request
          {resource, action} = context.match
          action = handlers[resource.name]?[action.name]
          if action?
            try
              yield action context
            catch error
              context.error error
          else
            context.respond.not_implemented()
        catch error
          context.error error
      catch error
        console.error error.stack
        response.statusCode = 500
        response.write "Server Error"
        response.end()

{resource} = require "shred"
{call} = require "when/generator"

describe = (url, api) ->
  root = {}
  for rname, {actions} of api.resources
    description = {}
    for aname, {method, request, response} of actions
      description[aname] = action = {method}
      if request?
        if request.type?
          action.headers = "content-type": request.type
      if response?
        if response.type?
          action.headers ?= {}
          action.headers.accept = response.type
        if response.status?
          action.expect = response.status
    do (rname, description) ->
      root[rname] = (resource) ->
        {template, path, query} = api.mappings[rname]
        # TODO: add support for query params
        if path?
          resource path, description
        else if template?
          components = for component in (template.split "/")[1..]
            if component[0] == ":"
              key = component[1..]
              "{#{key}}"
            else
              component
          resource ("/" + components.join "/"), description

  resource url, root

discover = (discovery, url) ->
  url ?= discovery
  # Create a bootstrap service here to do the discovery
  service = resource discovery,
    description: (resource) ->
      resource "/",
        get:
          method: "get"
          headers:
            "accept": "application/json"
          expect: 200

  call ->
    {data} = yield service.description.get()
    api = yield data
    describe url, api



module.exports = {discover, describe}

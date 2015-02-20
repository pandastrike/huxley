{call} = require "when/generator"
{processor} = require "../src"
initialize = require "./handlers"
api = require "./api"
api.base_url = "http://localhost:8080"

call ->
  (require "http")
  .createServer yield (processor api, initialize)
  .listen 8080
  console.log "listening on 8080"

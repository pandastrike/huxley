{Builder} = require "../../src"
builder = new Builder "blog-api"

builder.define "blogs",
  path: "/blogs"
.post
  as: "create"
  creates: "blog"

builder.define "blog",
  template: "/blogs/:name"
.get()
.put()
.delete()
.post
  creates: "post"
.schema
  required: ["name", "title"]
  properties:
    name: type: "string"
    title: type: "string"

builder.define "post",
  template: "/blog/:name/:key"
.get()
.put()
.delete()
.schema
  required: ["key", "title", "content"]
  properties:
    key: type: "string"
    title: type: "string"
    content: type: "string"

builder.reflect()

module.exports = builder.api

{Builder} = require "../src"
builder = new Builder "huxley-api"

builder.define "clusters",
  path: "/clusters"
.post
  as: "create"
  creates: "cluster"

builder.define "cluster",
  template: "/cluster/:cluster_url"
.get()
.delete()

builder.define "remotes",
  template: "/remotes"
.post
  as: "create"
  creates: "remote"

builder.define "remote",
  template: "/remote/:remote_id"
.delete()

builder.define "users",
  path: "/users"
.post
  as: "create"
  creates: "user"

#builder.define "blogs",
#  path: "/blogs"
#.post
#  as: "create"
#  creates: "blog"
#
#builder.define "blog",
#  template: "/blogs/:name"
#.get()
#.put()
#.delete()
#.post
#  creates: "post"
#.schema
#  required: ["name", "title"]
#  properties:
#    name: type: "string"
#    title: type: "string"
#
#builder.define "post",
#  template: "/blog/:name/:key"
#.get()
#.put()
#.delete()
#.schema
#  required: ["key", "title", "content"]
#  properties:
#    key: type: "string"
#    title: type: "string"
#    content: type: "string"

builder.reflect()
console.log builder.api

module.exports = builder.api

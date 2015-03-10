{Builder} = require "pbx"
builder = new Builder "huxley-api"

builder.define "clusters",
  path: "/clusters"
.post
  as: "create"
  creates: "cluster"

builder.define "cluster",
  template: "/cluster/:cluster_id"
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


builder.reflect()
console.log builder.api

module.exports = builder.api

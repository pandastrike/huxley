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

builder.define "deployments",
  path: "/deployments"
.post
  as: "create"
  creates: "deployment"
.get
  as: "query"

builder.define "deployment",
  template: "/deployment/:deployment_id"
.get()
.delete()

# @deprecated
builder.define "status",
  template: "/deployment/:deployment_id/status"
.post
  creates: "status"

builder.reflect()

module.exports = builder.api

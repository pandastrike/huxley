{Builder} = require "pbx"
builder = new Builder "huxley-api"

builder.define "clusters",
  path: "/clusters"
.post
  as: "create"
  creates: "cluster"
.put()
.get
  as: "list"

builder.define "cluster",
  template: "/cluster/:cluster_name"
.delete()
.get()


builder.define "remotes",
  template: "/remotes"
.post
  as: "create"
  creates: "remote"

builder.define "remote",
  template: "/remote/:cluster_id/:repo_name"
.delete()

builder.define "pending",
  path: "/pending"
.get()

builder.define "profiles",
  path: "/profiles"
.post
  as: "create"
  creates: "profile"

builder.define "profile",
  template: "/profile"
.get()

builder.define "deployments",
  path: "/deployments"
.post
  as: "create"
  creates: "deployment"

builder.define "deployment",
  template: "/deployment/:deployment_id"
.put
  as: "update"

builder.reflect()

module.exports = builder.api

{Builder} = require "pbx"
builder = new Builder "huxley-api"

builder.define "clusters",
  path: "/clusters"
.post
  as: "create"
  creates: "cluster"
.get
  as: "list"
.put
  as: "update"

builder.define "cluster",
  template: "/cluster/:name"
.post as: "delete"
.get()


builder.define "remotes",
  path: "/remotes"
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
  path: "/profile"
.get()

builder.define "deployments",
  path: "/deployments"
.post
  as: "create"
  creates: "deployment"
.put
  as: "update"


builder.reflect()

module.exports = builder.api

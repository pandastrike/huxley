async = (require "when/generator").lift
{call} = require "when/generator"
{Memory} = require "pirate"

pandacluster = require "panda-cluster"

make_key = -> (require "key-forge").randomKey 16, "base64url"

adapter = Memory.Adapter.make()


module.exports = async ->

  clusters = yield adapter.collection "clusters"
  users = yield adapter.collection "users"

  clusters:

    ###
    cluster: cluster_url
      email: String
      url: String
      name: String
    ###

    create: async ({respond, url, data}) ->
      console.log "****hellow orld"
      data = (yield data)
      cluster_url = make_key()
      console.log "****cluster_url: ", cluster_url
      {stack_name, cluster_name, email, secret_token, key_pair, public_keys} = data
      user = yield users.get email

      #if user && data.secret_token == user.secret_token
      if user
        console.log "*****user retrieved in create cluster: ", user
        cluster_entry =
          email: email
          url: cluster_url
          name: cluster_name || stack_name
        cluster_res = yield clusters.put cluster_url, cluster_entry

        pandacluster.create_cluster data
        respond 201, "", {location: (url "cluster", {cluster_url})}
      else
        respond 401, "invalid email or token"

  cluster:

    # FIXME: pass in secret token in auth header
    delete: async ({respond, match: {path: {cluster_url}}, request: {headers: {authorization}}}) ->
      console.log "*****hitting delete in handlers with url: ", cluster_url
      console.log "*****all clusters: ", clusters
      cluster = yield clusters.get cluster_url
      console.log "*****retrieved cluster: ", cluster
      if cluster
        {email, name} = cluster
        user = yield users.get email
        # FIXME: validate secret token
        #if user && secret_token == user.secret_token
        if user
          request_data =
            aws: user.aws
            cluster_name: name
          clusters.delete cluster_url
          # FIXME: removed yield in clusters.delete
          console.log "*****delete request_data: ", request_data
          pandacluster.delete_cluster request_data
          respond 200, "cluster #{name} is being processed for deletion"
        else
          respond 401, "invalid email or token"
      else
        respond 404, "cluster not found"

    get: async ({respond, match: {path: {cluster_url}}, request: {headers: {authorization}}}) ->
      clusters = (yield clusters)
      cluster = (yield clusters.get cluster_url)
      if cluster
        console.log "*****get cluster: ", cluster
        {email} = cluster
        user = yield users.get email
        # FIXME: validate secret token
        #if user && secret_token == user.secret_token
        if user
          request_data =
            aws: user.aws
            cluster_name: cluster.name
          console.log "*****pandacluster: ", pandacluster
          cluster_status = yield pandacluster.get_cluster_status request_data
          console.log "*****cluster_status: ", cluster_status
          respond 200, {cluster_status}
        else
          respond 401, "invalid email or token"
      else
        respond 404, "cluster not found"

  users:

    ###
    user: email
      public_keys: Array[String]
      key_pair: String
      aws: Object
      email: String
      secret_token: String
    ###

    create: async ({respond, url, data}) ->
      key = make_key()
      console.log "*****create user data: ", data
      data.secret_token = key
      user = yield data
      user.secret_token = key
      console.log "*****user created: ", user
      yield users.put user.email, user
      respond 201, {user}




#async = (require "when/generator").lift
#{call} = require "when/generator"
#{Memory} = require "pirate"
#{validate} = (require "../../src").filters
#
#make_key = -> (require "key-forge").randomKey 16, "base64url"
#
#adapter = Memory.Adapter.make()

#module.exports = async ->
#
#  blogs = yield adapter.collection "blogs"
#
#  blogs:
#
#    create: validate async ({respond, url, data}) ->
#      blog = (yield data)
#      {name} = blog
#      blog.posts = {}
#      yield blogs.put name, blog
#      respond 201, "", location: url "blog", {name}
#
#  blog:
#
#    # create post
#    post: validate async ({respond, url, data, match: {path: {name}}}) ->
#      blog = yield blogs.get name
#      post = yield data
#      {key} = post
#      blog.posts[key] = post
#      yield blogs.put name, blog
#      respond 201, "",
#        location: (url "post", {name, key})
#
#    get: async ({respond, match: {path: {name}}}) ->
#      blog = yield blogs.get name
#      respond 200, blog
#
#    put: validate async ({respond, data, match: {path: {name}}}) ->
#      yield blogs.put name, (yield data)
#      respond 200
#
#    delete: async ({respond, match: {path: {name}}}) ->
#      yield blogs.delete name
#      respond 200
#
#  post:
#
#    get: async ({respond, match: {path: {name, key}}}) ->
#      blog = yield blogs.get name
#      if (post = blog.posts[key])?
#        respond 200, post
#      else
#        respond.not_found()
#
#    put: validate async ({respond, data, match: {path: {name, key}}}) ->
#      blog = yield blogs.get name
#      if (post = blog.posts[key])?
#        blog.posts[key] = (yield data)
#        respond 200
#      else
#        respond.not_found()
#
#    delete: async ({respond, match: {path: {name, key}}}) ->
#      blog = yield blogs.get name
#      if (post = blog.posts[key])?
#        delete blog.posts[key]
#        respond 200
#      else
#        respond.not_found()

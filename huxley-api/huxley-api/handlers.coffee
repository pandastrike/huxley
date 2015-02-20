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
      data = (yield data)
      cluster_url = make_key()
      {stack_name, cluster_name, email, secret_token, key_pair, public_keys} = data
      user = yield users.get email

      #if user && data.secret_token == user.secret_token
      if user
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
      cluster = yield clusters.get cluster_url
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
        {email} = cluster
        user = yield users.get email
        # FIXME: validate secret token
        #if user && secret_token == user.secret_token
        if user
          request_data =
            aws: user.aws
            cluster_name: cluster.name
          cluster_status = yield pandacluster.get_cluster_status request_data
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
      data.secret_token = key
      user = yield data
      user.secret_token = key
      yield users.put user.email, user
      respond 201, {user}


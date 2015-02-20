async = (require "when/generator").lift
{call} = require "when/generator"
{Memory} = require "pirate"
{validate} = (require "../../src").filters

make_key = -> (require "key-forge").randomKey 16, "base64url"

adapter = Memory.Adapter.make()

module.exports = async ->

  blogs = yield adapter.collection "blogs"

  blogs:

    create: validate async ({respond, url, data}) ->
      blog = (yield data)
      {name} = blog
      blog.posts = {}
      yield blogs.put name, blog
      respond 201, "", location: url "blog", {name}

  blog:

    # create post
    post: validate async ({respond, url, data, match: {path: {name}}}) ->
      blog = yield blogs.get name
      post = yield data
      {key} = post
      blog.posts[key] = post
      yield blogs.put name, blog
      respond 201, "",
        location: (url "post", {name, key})

    get: async ({respond, match: {path: {name}}}) ->
      blog = yield blogs.get name
      respond 200, blog

    put: validate async ({respond, data, match: {path: {name}}}) ->
      yield blogs.put name, (yield data)
      respond 200

    delete: async ({respond, match: {path: {name}}}) ->
      yield blogs.delete name
      respond 200

  post:

    get: async ({respond, match: {path: {name, key}}}) ->
      blog = yield blogs.get name
      if (post = blog.posts[key])?
        respond 200, post
      else
        respond.not_found()

    put: validate async ({respond, data, match: {path: {name, key}}}) ->
      blog = yield blogs.get name
      if (post = blog.posts[key])?
        blog.posts[key] = (yield data)
        respond 200
      else
        respond.not_found()

    delete: async ({respond, match: {path: {name, key}}}) ->
      blog = yield blogs.get name
      if (post = blog.posts[key])?
        delete blog.posts[key]
        respond 200
      else
        respond.not_found()

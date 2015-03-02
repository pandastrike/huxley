{call} = require "when/generator"
{discover} = (require "../../src").client
amen = require "amen"
assert = require "assert"

amen.describe "Example blogging API", (context) ->

  context.test "Create a blog", (context) ->

    api = yield discover "http://localhost:8080"

    {response: {headers: {location}}} =
      (yield api.blogs.create name: "my-blog", title: "My Blog")

    blog = (api.blog location)

    context.test "Create a post", ->

      {response: {headers: {location}}} =
        (yield blog.post
          key: "my-first-post"
          title: "My First Post"
          content: "This is my very first post.")

      post = (api.post location)

      context.test "Get a post", ->

        {data} = yield post.get()
        {title, content, key} = yield data
        assert key == "my-first-post"
        assert title == "My First Post"
        assert content == "This is my very first post."

      context.test "Modify a post", ->

        {response: {statusCode}} = yield post.put
          key: "my-first-post"
          title: "My first updated post"
          content: "This is my very first post update."

        assert statusCode == 200

        {data} = yield post.get()
        {title, content} = yield data
        assert title == "My first updated post"
        assert content == "This is my very first post update."

    context.test "Get a blog", ->

      {data} = yield blog.get()
      {posts} = yield data
      assert posts["my-first-post"]?

module.exports =

  questions: ->
    [
      name: "service_name"
      description: "What do you want to call this Redis instance?"
      default: "redis"
    ,
      name: "port"
      description: "Port?"
      default: 6379
    ]

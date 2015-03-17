module.exports =

  # object, not function
  questions:
    [
      name: "service_name"
      description: "What is the service name?"
      default: process.cwd().split("/").pop()
    ,
      name: "port"
      description: "Port?"
      default: 6379
    ]

module.exports =

  # object, not function
  questions:
    [
      name: "service_name"
      description: "What is the service name of this mixin?"
      default: process.cwd().split("/").pop()
    ,
      name: "port"
      description: "On what port is the service listening?"
      default: 3010
    ,
      name: "start_command"
      description: "What is the application start command?"
      default: "npm start"
    ]

module.exports =

  questions: () ->
    [
      name: "service_name"
      description: "What is the mixin name?"
      default: process.cwd().split("/").pop()
    ,
      name: "port"
      description: "On what port is the mixin listening?"
      default: 80
    ,
      name: "start_command"
      description: "What is the application start command?"
      default: "npm start"
    ]

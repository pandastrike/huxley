module.exports =

  questions: () ->
    [
      name: "name"
      description: "What is the mixin name?"
      default: process.cwd().split("/").pop()
    ,
      name: "external_port"
      description: "What external port on the container is exposed?"
      default: undefined
    ,
      name: "internal_port"
      description: "What internal port in the container maps to the above?"
      default: 80
    ,
      name: "start"
      description: "What is the mixin start command?"
      default: "npm start"
    ,
      name: "exclusions"
      description: "Provide a comma separated list of mixins that cannot be co-located with this one (if any).\n"
      default: undefined
    ]

JSCK = (require "jsck").draft3

console.log "Bug: using 'id' as a property name"
try
  validator = new JSCK
    properties:
      id:
        required: true
        type: "string"

  console.log validator.validate {id: "foo"}

catch error
  console.error "Oh, dear me!"
  console.error error


console.log "Works: using 'key' as a property name"
try
  validator = new JSCK
    properties:
      key:
        required: true
        type: "string"

  console.log validator.validate {key: "foo"}

catch error
  console.error "Oh, dear me!"
  console.error error

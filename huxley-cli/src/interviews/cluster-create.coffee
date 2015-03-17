module.exports =

  # function, not object
  questions: ({spot_price, public_domain}) ->
    [
      name: "cluster_name"
      description: "Please enter a cluster name (leave empty to generate random name):"
      required: false
    ,
      name: "spot_price"
      description: "Please enter a spot price:"
      default: spot_price
    ,
      name: "public_domain"
      description: "Please enter your public domain:"
      default: public_domain
    ,
      name: "tags"
      description: "Please enter any tags:"
      default: "cloudformation"
    ]

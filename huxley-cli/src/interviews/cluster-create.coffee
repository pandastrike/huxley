module.exports =

  questions: ({spot_price, public_domain}) ->
    [
      name: "spot_price"
      description: "Please enter a spot price:"
      default: spot_price
    ,
      name: "public_domain"
      description: "Please enter the cluster's public domain:"
      default: public_domain
    ,
      name: "tags"
      description: "Please enter a single descriptive tag:"
      default: "huxley"
    ]

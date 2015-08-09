# For every mixin that is deployed on an ECS instance, we will need to ask for these.

module.exports = [
    name: "size"
    description: "Cluster Size [3-12]:"
    message: "Specify an integer between 3 and 12, inclusive."
    default: 3
    conform: (v) ->
      return false if Number.isNaN v
      return false if v % 1 != 0
      if 12 >= v >= 3 then true else false
  ,
    name: "type"
    description: "EC2 Instance Type:"
    enum: ["c1.medium", "c1.xlarge", "c3.large", "c3.xlarge", "c3.2xlarge", "c3.4xlarge", "m1.medium", "m1.large", "m1.xlarge", "m2.xlarge", "m2.2xlarge", "m2.4xlarge", "m3.medium" ,"m3.large", "m3.xlarge", "m3.2xlarge"]
    message: "Specify one among the allowed EC2 Instance Types: \nc1.medium, c1.xlarge, \nc3.large, c3.xlarge, c3.2xlarge, c3.4xlarge, \nm1.medium, m1.large, m1.xlarge, \nm2.xlarge, m2.2xlarge, m2.4xlarge, \nm3.medium, m3.large, m3.xlarge, m3.2xlarge"
    default: do ->
      if config.cluster && config.cluster.instance
        return config.cluster.instance
      else
        return "m1.medium"
  ,
    name: "virtualization"
    description: "Instance Virtualizaiton Type:"
    enum: ["pv", "hvm"]
    message: "Specify one among the allowed virtualization types: pv, hvm"
    default: do ->
      if config.cluster && config.cluster.virtualization
        return config.cluster.virtualization
      else
        return "hvm"
  ,
    name: "zone"
    description: "Availability Zone:"
    default: config.aws.availability_zone
  ,
    name: "price"
    description: "Spot Bid [or 0 for on-demand]:"
    message: "Specify a bid ($/hr) greater that 0 for a Spot Instance, or specify 0 to use an On-Demand Instance."
    default: do ->
      if config.cluster && config.cluster.price
        return config.cluster.price
      else
        return 0
    conform: (v) ->
      return false if Number.isNaN v
      if v >= 0 then true else false
]

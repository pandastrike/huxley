module.exports =

  questions: (config) ->
      console.log "This utility will walk you through configuring a Huxley cluster."
      console.log "It pulls from your local config or tries to guess sane defaults."
      console.log " "
      console.log "See https://github.com/pandastrike/huxley/wiki for definitive documentation"
      console.log " "
      console.log "Press ^C at any time to quit."
      [
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
        enum: ["c1.medium", "c1.xlarge", "c3.large", "c3.xlarge", "c3.2xlarge", "c3.4xlarge", "m1.medium", "m1.large", "m1.xlarge", "m2.xlarge", "m2.2xlarge", "m2.4xlarge", "m3.large", "m3.xlarge", "m3.2xlarge"]
        message: "Specify one among the allowed EC2 Instance Types: \nc1.medium, c1.xlarge, \nc3.large, c3.xlarge, c3.2xlarge, c3.4xlarge, \nm1.medium, m1.large, m1.xlarge, \nm2.xlarge, m2.2xlarge, m2.4xlarge, \nm3.large, m3.xlarge, m3.2xlarge"
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
            return "pv"
      ,
        name: "region"
        description: "AWS Region:"
        enum: ["ap-northeast-1", "ap-southeast-1", "ap-southeast-2", "eu-central-1", "eu-west-1", "sa-east-1", "us-east-1", "us-west-1", "us-west-2"]
        message: "Specify one among the allowed AWS Regions: \nap-northeast-1, ap-southeast-1, ap-southeast-2, \neu-central-1, eu-west-1, \nsa-east-1, \nus-east-1, us-west-1, us-west-2"
        default: config.aws.region
      ,
        name: "zone"
        description: "Availability Zone:"
        default: config.aws.availability_zone
      ,
        name: "key"
        description: "Default SSH Key:"
        default: config.aws.key_name
      ,
        name: "channel"
        description: "CoreOS Channel:"
        enum: ["stable", "beta", "alpha"]
        message: "Specify among the allowed CoreOS channels: alpha, beta, stable"
        default: do ->
          if config.coreos && config.coreos.channel
            return confg.coreos.channel
          else
            return "stable"
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
      ,
        name: "domain"
        description: "Public Domain:"
        message: "Specify a publicly accessable domain for the cluster:"
        default: config.cluster.public if config.cluster
      ,
        name: "tags"
        description: "Descriptive Tag:"
        minLength: 1
        maxLength: 254
        default: do ->
          if config.cluster && config.cluster.tags
            return config.cluster.tags
          else
            return "huxley"
      ]

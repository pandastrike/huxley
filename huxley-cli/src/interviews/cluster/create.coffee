module.exports =

  questions: (config) ->
      console.log "This utility will walk you through configuring a Huxley cluster."
      console.log "It pulls from your local config or tries to guess sane defaults."
      console.log " "
      console.log "See https://github.com/pandastrike/huxley/wiki for definitive documentation"
      console.log " "
      console.log "Press ^C at any time to quit."
      [
        name: "production"
        description: "Is Production? (y/n):"
        enum: ["yes", "no", "y", "n", "true", "false"]
        message: "Specify one among the answers ['yes', 'no', 'y', 'n', 'true', 'false']"
        default: "no"
      ,
        name: "region"
        description: "AWS Region:"
        enum: ["ap-northeast-1", "ap-southeast-1", "ap-southeast-2", "eu-central-1", "eu-west-1", "sa-east-1", "us-east-1", "us-west-1", "us-west-2"]
        message: "Specify one among the allowed AWS Regions: \nap-northeast-1, ap-southeast-1, ap-southeast-2, \neu-central-1, eu-west-1, \nsa-east-1, \nus-east-1, us-west-1, us-west-2"
        default: config.aws.region
      ,
        name: "key"
        description: "Default SSH Key:"
        default: config.aws.key_name
      ,
        name: "domain"
        description: "Public Domain:"
        message: "Specify a publicly accessable domain for the cluster:"
        default: config.cluster.domain if config.cluster
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

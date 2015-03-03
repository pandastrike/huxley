# Huxley

### Modern Web Deployment via Microservice Clustering
---

> **Warning:** This is an experimental project under heavy development.  It's awesome and becoming even more so, but it is a work in progress.

---
Huxley is a tool meant to manage the deployment of your application.  It launches your app as a set of micro-services, allocating the needed resources from your Amazon Web Services account.  With simple, human-readable configuration and just a few commands, your app is up and running.  We've focused on providing both Developers and Operations professionals a graceful workflow.  It is a tool that does the heavy lifting for you while staying out of your way.  Huxley aims to be like a more powerful, personal Heroku.

We encourage you to learn more abut Huxley through its documentation. Where you begin depends on what you want to know:
- **Who:** [Panda Strike][1] is a shop that specializes in providing both development and DevOps at scale.  Huxley represents the culmination of those skill sets.  We're committed to open source software and wish to foster a community to adopt, grow, and refine this technology.
- **What:** If you'd like to know what gets constructed when you build a Huxley cluster, check out [cluster-architecture.md][2].
- **Why:** We started this project because we see that modern web development needs a new model, a new way of thinking about the problem.  To see how Huxley's approach, checkout [huxley-model.md][3].
- **How:** The remainder of this document is dedicated to the user experience and how you accomplish what has been described.
---

# Quick Start
## Requirements
Before we get started, you should know that Huxley actually has two parts, a CLI and an API.  The CLI accepts simple user commands and fills in the gaps for you with context it has stored.  The API holds a multitude of other components and does cool things on your behalf, like interfacing with your cloud provider and your cluster.  The API server must be online, but if someone on your team already has it setup, you can skip to the [CLI tutorial][4].
<br>
<br>
Both the CLI and API require the ES6 technologies included in Node 0.12+ and CoffeeScript 1.9+.
```shell
git clone https://github.com/creationix/nvm.git ~/.nvm
source ~/.nvm/nvm.sh && nvm install 0.12
npm install -g coffee-script
```

## API Server
### Installation
The Huxley API server is easily installed via npm.  You can run this locally on your machine, in a Docker container, or on a cloud instance.
```shell
npm install pandastrike/huxley
coffee --nodejs --harmony huxley/huxley-api/src/index.coffee
```
By default, the API server responds to HTTP requests on port 8080.  Wherever you end up running the API server, you'll need to point your CLI tool at it (see below).  So remember its URL and share it with your team.

## CLI Tool
### Installation
The CLI tool is a globally installed npm package that yields a symlinked executable.
```shell
npm install pandastrike/huxley
npm install -g huxley/huxley-cli
```
Next, you'll need to establish some configuration information.  Huxley stores reusable configuration data so you don't have to type the same things over and over.  You'll end up only needed to enter simple commands, while Huxley uses various config files as the context to fill in the gaps.

The first thing to establish is your Huxley home config. Place a yaml file in your $HOME directory, `~/.huxley`.  You will be placing some sensitive information here, so we're going to make this clear:  

>**NEVER Include this File in a Repository or Share this Information Publicly!!**

<br>
**.huxley**
```yaml
#==========
# Required
#==========
huxley:
  email: pat@acme.com
  secret_token: Random_Token_Huxley_Gives_You
  url: "http://myserver.acme.com:3000"  
  # Fully formed URL pointing at the API server.
  # YAML requires quotes if a colon is used in a string.

aws:
  id: My_AWS_ID
  key: Password123
  region: us-west-1
  key_name: Name-of-SSH-Key   # This is key you have associated with your AWS account.

#==========
# Optional
#==========
public_keys:
  - List of public SSH keys
  - Specify one key per line
  - Grants cluster-wide access to whomever holds the paired private key.
```

### Command-Line Guide
The command-line tool is accessed via several sub-commands. Here is a list of currently available sub-commands.
```
--------------------------------------------
Usage: pandahook COMMAND [arg...]
--------------------------------------------
Follow any command with "help" for more information.

A tool to manage githook scripts and deploy them to your hook-server.  

Commands:
cluster
  create      Spins up a CoreOS cluster on Amazon's EC2 cloud service according to several specified options.
  delete      Terminates the specified CoreOS cluster on Amazon's EC2 cloud service and deletes its cloud stack.
  wait        Polls cluster status until creation is successful.
user
  create      Creates user account with a secret token.
```



[1]:https://www.pandastrike.com/
[2]:https://github.com/pandastrike/huxley/blob/feature/init-merge/cluster-architecture.md
[3]:https://github.com/pandastrike/huxley/blob/feature/init-merge/huxley-model.md
[4]:https://github.com/pandastrike/huxley#cli-tool

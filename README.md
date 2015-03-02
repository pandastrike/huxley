# Huxley

### Modern Web Deployment via Microservice Clustering
---

> **Warning:** This is an experimental project under heavy development.  It's awesome and becoming even more so, but it is a work in progress.

---
Huxley is a tool meant to manage the deployment of your application.  It launches your app as a set of micro-services, allocating the needed resources from your Amazon Web Services account.  With simple, human-readable configuration and just a few commands, your app is up and running.  We've focused on providing both Developers and Operations professionals a graceful workflow.  It is a tool that does the heavy lifting for you while staying out of your way.  Huxley aims to be like a more powerful, personal Heroku.

We encourage you to learn more abut Huxley through its documentation. Where you begin depends on what you want to know:
- **Who:** [Panda Strike][1] is a shop that specializes in providing both development and DevOps at scale.  Huxley represents the culmination of those skill sets.  We're committed to open source software and wish to foster a community to adopt, grow, and refine this technology.
- **What:** If you'd like to know what gets constructed when you build a Huxley cluster, check out [cluster-architecture.md][2].
- **Why:** We started this project because we see that modern web development needs a new model, and new way of thinking about the problem.  To see how Huxley's approach, checkout [huxley-model.md][3].
- **How:** The remainder of this document is dedicated to the user experience and how you accomplish what has been described.
---

# Quick Start


## Requirements
Both the CLI and API require the ES6 technologies included in Node 0.12+ and CoffeeScript 1.9+.
```shell
git clone https://github.com/creationix/nvm.git ~/.nvm
source ~/.nvm/nvm.sh && nvm install 0.12
npm install -g coffee-script
```

## Installation
Both the CLI and API are is easily installed via npm.  

- The Huxley API server would be deployed on a running server
```shell
npm install pandastrike/huxley
cd huxley/huxley-api/huxley-api
coffee --nodejs --harmony index.coffee
```

- The CLI tool is installed globally to yield an executable tool.
```shell
npm install pandastrike/huxley
cd huxley/huxley-cli
npm install -g .
```



Running the API simply involves `coffee --nodejs --harmony project_root/huxley-api/huxley-api/index.coffee`.  

This requires Node.js version v0.11 or higher.

### Command-Line Tool
If you'd like to use Huxley's command-line tool on your local machine, install it globally.
```shell
npm install -g huxley-cli
```
This gives you a symlinked executable to invoke on your command-line. See *Command-Line Guide* below for more information on this executable.

## Command-Line Guide
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

### Configuration Dotfile for the CLI
Reusable configuration data is stored in the dotfile `.pandacluster.cson`.  This keeps you from having to re-type the same data repeatedly into commands.  This data must be provided in your code if you plan to access the library programmatically.  Here is a sample file layout:

An example configuration file is [detailed here](https://github.com/pandastrike/huxley/blob/master/.pandacluster.cson.example)

## TODO
- Finish documentation (especially for "help" commands)
- Write secret_token to config after creating user
- Consider writing cluster_id to config after creating cluster

[1]:https://www.pandastrike.com/
[2]:https://github.com/pandastrike/huxley/blob/feature/init-merge/cluster-architecture.md
[3]:https://github.com/pandastrike/huxley/blob/feature/init-merge/huxley-model.md

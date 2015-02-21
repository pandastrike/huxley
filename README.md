#Huxley API + CLI
============

### Huxley is the API server and CLI tool for [Panda-Cluster](https://github.com/pandastrike/panda-cluster).
---

> **Warning:** This is an experimental project under heavy development.  It's awesome and becoming even more so, but it is a work in progress.

---
The Huxley API server can accept HTTP requests to create and delete CoreOS cluster formations.  It can also run "wait", which will poll a cluster's status until it is successfully created.

## Installation
Huxley API + CLI is easily installed via npm.  The Huxley API server would be deployed on a running server, and the CLI tool would be run locally.  

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

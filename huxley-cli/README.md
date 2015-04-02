# Huxley

### Automated Deployment for the Modern Web
---

> **Warning:** This is an experimental project under heavy development.  It's awesome and becoming even more so, but it is a work in progress.

## Overview
Huxley manages the deployment of your application.  It launches your app as a set of micro-services, allocating the needed resources from your Amazon Web Services account.  With simple, human-readable configuration and just a few commands, your app is up and running.  

We've focused on providing both developers and operations professionals a graceful workflow.  It is a tool that does the heavy lifting for you while staying out of your way.  Huxley aims to be like a more powerful, personal Heroku.

We encourage you to learn more about Huxley by visiting [Huxley's wiki][1], which provides more detailed documentation.


## Requirements
Huxley makes use of the ES6 technologies included in Node 0.12+ and CoffeeScript 1.9+.  Tutorials in repository assume you have both installed.  The following commands will setup Node and CoffeeScript on machines without these requirements.
```shell
git clone https://github.com/creationix/nvm.git ~/.nvm
source ~/.nvm/nvm.sh && nvm install 0.12
npm install -g coffee-script
```
Huxley's code uses two components, an API server and a CLI tool.  The API wraps libraries that do cool things on your behalf.  The CLI makes using Huxley easy.  It accepts simple user commands and prepares the complex configurations that the API server needs.

So, in summary, you need the CLI on your local machine and you need an API server running somewhere.  For the API, you have three options:

1. You can use Panda Strike's API server that we have running for your convenience at `https://huxley.pandastrike.com`.  Note the use of HTTPS.  Connections to port 80 are rejected.
2. You can use an API server that someone else you know already has setup.
3. You can launch your own API server.

If (1) or (2) describe your situation, make sure you know the API server's address and then read the [Huxley CLI Guide][2] next to learn how to get started on the CLI.

If you wish to setup your own API server, please see the [Huxley API Guide][3] for a complete walkthrough.


[1]:https://github.com/pandastrike/huxley/wiki
[2]:https://github.com/pandastrike/huxley/wiki/Huxley-CLI-Guide
[3]:https://github.com/pandastrike/huxley/wiki/Huxley-API-Guide

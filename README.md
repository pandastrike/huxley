# Huxley

### Modern Web Deployment via Microservice Clustering
---

> **Warning:** This is an experimental project under heavy development.  It's awesome and becoming even more so, but it is a work in progress.

---
Huxley is a tool meant to manage the deployment of your application.  It launches your app as a set of micro-services, allocating the needed resources from your Amazon Web Services account.  With simple, human-readable configuration and just a few commands, your app is up and running.  We've focused on providing both Developers and Operations professionals a graceful workflow.  It is a tool that does the heavy lifting for you while staying out of your way.  Huxley aims to be like a more powerful, personal Heroku.

We encourage you to learn more abut Huxley through its documentation. Where you begin depends on what you want to know:
- **Who:** [Panda Strike][1] is a shop that specializes in providing both development and DevOps at scale.  Huxley represents the culmination of those skill sets.  We're committed to open source software and wish to foster a community to adopt, grow, and refine this technology.
- **What:** If you'd like to know what gets constructed when you build a Huxley cluster, check out [cluster-architecture.md][2].
- **Why:** We started this project because we see that modern web development needs a new model, a new way of thinking about the problem.  To see how Huxley's approach, checkout [huxley-model.md (Coming Soon)][3].
- **How:** The remainder of this document is dedicated to the user experience and how you accomplish what has been described.


# Quick Start
## Requirements
Before we get started, you should know that Huxley actually has two parts, a CLI and an API.  The API holds a multitude of components and does cool things on your behalf, like interfacing with your cloud provider and your cluster.  The CLI accepts simple user commands and prepares a fully-formed (and sometimes complex) configuration with context it has stored.  Then it hits the API server with this request and asks it to act.  Therefore, to use Huxley, an API server must be running somewhere.  You have three options:

1. You can use Panda Strike's API server that we have running for your convenience at `huxley.pandastrike.com`
2. You can use an API server that someone else you know already has setup
3. You can launch your own API server.

If (1) or (2) describe your situation, make sure you know the API server's address and then read the *CLI tutorial* next.
<br>
<br>
**Please Note:** that both the CLI and API require the ES6 technologies included in Node 0.12+ and CoffeeScript 1.9+.  Tutorials in the next sections assume you have the following installed.
```shell
git clone https://github.com/creationix/nvm.git ~/.nvm
source ~/.nvm/nvm.sh && nvm install 0.12
npm install -g coffee-script
```

## CLI Tool
### Installation
The CLI tool is a globally installed npm package that yields a symlinked executable.
```shell
npm install -g huxley-cli
```
Next, you'll need to establish some configuration information.  Huxley stores reusable configuration data so you don't have to type the same things over and over.  You'll end up only needed to enter simple commands, while Huxley uses various config files as the context to fill in the gaps.

The first thing to establish is your Huxley home config. Place a yaml file in your $HOME directory, `~/.huxley`.  You will be placing some sensitive information here, so we're going to make this clear:  

>**NEVER Include this File in a Repository or Share this Information Publicly!!**

<br>
**.huxley**
```yaml
huxley:
url: "http://huxley.pandastrike.com"    # Specify the API server location

aws:
id: MyAWSIdentity
key: Password123
region: us-west-1
availability_zone: us-west-1c
key_name: My-AWS-Key            # SSH key associated with your AWS account.

public_keys:
- List of public SSH keys
- One key per line
- Grants cluster access to listed users

spot_price: 0.009
public_domain: acme.com
```

### Command Guide
The command-line tool is organized with respect to several resources.  To get the whole list of resources and commands available to the CLI, simply type `huxley` into the command-line.

Please see [this example project][4] for an end-to-end walkthrough.

## API Server
### Installation
The Huxley API server is easily installed.  You can run the server locally on your machine, in a Docker container, or on a cloud instance.  **You must make sure that your platform has openssh installed.**

Now, install the API server and activate.
```shell
# Pull down the huxley repository and install dependencies.
git clone https://github.com/pandastrike/huxley.git
cd huxley/huxley-api
npm install
npm start
```
By default, the API server responds to HTTP requests on port 8080.  Wherever you end up running the API server, you'll need to point your CLI tool at it (see below).  So remember the server's URL and share it with your team.



[1]:https://www.pandastrike.com/
[2]:https://github.com/pandastrike/panda-cluster/blob/feature/master/cluster-architecture.md
[3]:https://github.com/pandastrike/huxley/blob/feature/master/huxley-model.md
[4]:https://github.com/pandastrike/vanilla

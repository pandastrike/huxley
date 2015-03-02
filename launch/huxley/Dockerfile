FROM base/archlinux
MAINTAINER Peter Nguyen (peter@pandastrike.com)
#===============================================================================
# Huxley: Huxley API Server
#===============================================================================
# This Dockerfile describes a container running Huxley's API server.  By accepting
# requests over HTTPS, the server makes calls into your cloud provider and cluster
# to get things setup for you.

# Install requirements, a couple dependencies, and some tools that make life easier.
RUN pacman -Syu --noconfirm
RUN pacman-db-upgrade
RUN pacman -S --noconfirm git openssh wget vim tmux nodejs
RUN npm install -g coffee-script

# Create directory to hold SSH data
RUN mkdir root/.ssh               && \
  touch root/.ssh/authorized_keys && \
  chmod -R 700 root/.ssh

# Add a configuration file so the hook-server allows agent-forwarding and isn't picky
# about connecting to wherever we ask.
RUN echo "Host *" >> root/.ssh/config                     && \
  echo "  ForwardAgent yes "  >> root/.ssh/config         && \
  echo "StrictHostKeyChecking no" >> root/.ssh/config     && \
  echo "UserKnownHostsFile=/dev/null" >> root/.ssh/config

# Pull the API's master SSH private key from the passive repo on the hook server.
RUN git clone git://hook.splendid-shield.cluster:2001/passive/huxley-key.git
RUN cp huxley-key/huxley /root/.ssh/. && chmod 400 /root/.ssh/huxley
RUN rm -rf huxley-key

# Pull the API server repo from the hook server and install.
RUN git clone git://hook.splendid-shield.cluster:2001/repos/huxley.git
RUN cd huxley/huxley-api && npm install
RUN cd huxley/huxley-cli && npm install

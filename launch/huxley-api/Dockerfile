FROM base/archlinux
MAINTAINER Peter Nguyen (peter@pandastrike.com)
#===============================================================================
# Panda-Cluster: Huxley API Server
#===============================================================================
# This Dockerfile describes a hook-server tailored to act upon an app running
# the CoreOS stack.  Hook-servers contain "bare" git repositories with one or
# more githooks, scripts you trigger with git commands.

# Hook-Server & CoreOS Requirements: (1) git, (2) fleetctl
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

RUN git clone https://github.com/pandastrike/huxley.git
RUN cd huxley/huxley-api && npm install
RUN cd huxley/huxley-cli && npm install

CMD coffee --nodejs --harmony huxley/huxley-api/huxley-api/index.coffee

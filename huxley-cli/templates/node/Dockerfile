FROM base/archlinux
MAINTAINER Peter Nguyen (peter@pandastrike.com)
#===============================================================================
# Node.js
#===============================================================================
# This Dockerfile describes a Node.js web server.

RUN pacman -Syu --noconfirm
RUN pacman-db-upgrade
RUN pacman -S --noconfirm jre7-openjdk-headless wget vim tmux git nodejs 

# Install Node
RUN git clone git@github.com:pandastrike/vanilla.git node

# Install CoffeeScript
RUN npm install -g coffee-script

FROM base/archlinux
MAINTAINER David Harper (david@pandastrike.com)
#===============================================================================
# Arch Plus
#===============================================================================
# This describes a container with an environment that makes iterating during
# development faster.  We tend to use Archlinux for deployments, but we also tend
# to repeatedly download this stuff too. However, when running production,
# the latest version of these should be installed.

RUN pacman -Syu --noconfirm
RUN pacman-db-upgrade
RUN pacman -S --noconfirm jre7-openjdk-headless wget vim tmux git nodejs
RUN npm install -g coffee-script

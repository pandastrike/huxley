#
# Huxley API Server Dockerfile
#

# Pull base image.
FROM base/arch

# Update system and install required packages.
RUN pacman -Syu --noconfirm
RUN pacman-db-upgrade
RUN pacman -S --noconfirm git nodejs openssh

# Install Node dependencies that must be global.
RUN npm install -g coffee-script

# Install Huxley API.
COPY . /huxley-api
RUN cd /huxley-api && npm install

# Define working directory.
WORKDIR /huxley-api

# Set up a environment variable to signal the server
# to expect to find a Redis server running on the given
# host on the default port (6379).
# Docker will automatically create an entry in the `/etc/hosts`
# file when running in linked mode.
# See https://docs.docker.com/userguide/dockerlinks/#updating-the-etchosts-file
ENV REDIS_HOST=redis

# Define default command.
CMD ["sh", "-c", "eval $(ssh-agent) && npm start"]

# Expose ports.
EXPOSE 8080

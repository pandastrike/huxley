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

# Define default command.
CMD ["sh", "-c", "eval $(ssh-agent) && npm start"]

# Expose ports.
EXPOSE 8080

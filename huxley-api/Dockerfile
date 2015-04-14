FROM pandastrike/arch_plus
MAINTAINER Peter Nguyen (peter@pandastrike.com)

# Update system and install required packages.
RUN pacman -S --noconfirm openssh

# Install Huxley API.
RUN git clone -b development/alpha-05  https://github.com/pandastrike/huxley.git /huxley-api
RUN cd /huxley-api/huxley-api && npm install

# Define working directory.
WORKDIR /huxley-api

# Define default command.
CMD ["sh", "-c", "eval $(ssh-agent) && npm start"]

# Expose ports.
EXPOSE 8080

FROM pandastrike/arch_plus
MAINTAINER David Harper (david@pandastrike.com)

# Create a directory to store cluster agent keys.
RUN mkdir .huxley-agent-keys

# Install Huxley API.
RUN git clone https://github.com/pandastrike/huxley.git
RUN cd /huxley/huxley-api && git checkout tags/v1.0.0-alpha-08 && npm install

# Define default command.
WORKDIR /huxley/huxley-api
# docker run -d -p 80:8080 --name api pandastrike/huxley_api /bin/bash -c "
#   ssh-agent coffee --nodejs --harmony src/server.coffee"

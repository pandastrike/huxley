FROM pandastrike/arch_plus
MAINTAINER David Harper (david@pandastrike.com)

# Create a directory to store cluster agent keys.
RUN mkdir .huxley-agent-keys

# Install Huxley API.
RUN git clone https://github.com/pandastrike/huxley.git
RUN cd /huxley/huxley-api && git checkout tags/v1.0.0-alpha-04.1 && npm install
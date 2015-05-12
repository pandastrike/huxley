#===============================================================================
# Huxley API - Helpers - Key Management
#===============================================================================
# Huxley needs random numbers in several places.  IDs for resources are assigned
# with them and SSH keys grant access.  These helper functions handle their
# management.
{join} = require "path"
{async, read, shell} = require "fairmont"  # utility library
key_forge = require "key-forge"     # cryptography

module.exports =
  # Create a random authorization token, defaulting to 16 bytes long and using
  # URL safe characters.
  generate: (size = 16, encoding = "base64url") ->
    key_forge.randomKey size, encoding

  ssh:
    # Temporary measure.  Read in the master SSH public key from a file in this
    # code's path.  The key gets placed on every cluster this server creates.
    read: async () -> yield read join __dirname, "..", "huxley_master.pub"

    # This creates an SSH keypair and returns both the public and private halves.
    generate: async () ->
      id = key_forge.randomKey 16
      dir = join process.env.HOME, ".huxley-agent-keys"

      yield shell "ssh-keygen -t rsa -C 'cluster_agent_master' -N '' " +
        "-f #{join dir, id}"

      return {
        public: yield read join dir, "#{id}.pub"
        private: yield read join dir, id
      }

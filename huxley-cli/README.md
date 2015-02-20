-----------------------------------------------
Usage: huxley-cli COMMAND [arg...]
-----------------------------------------------
Follow any command with "help" for more information.

A tool to manage CoreOS clusters and deploy them on AWS with your account.

You must have a ~/.pandaconfig.cson file with the correct key value pairs.

An example configuration file is detailed on the [GitHub repo](https://github.com/pandastrike/panda-cluster/tree/feature/refactor-to-sketch)


-----------------------------------------------
Commands:
-----------------------------------------------
  cluster
    create                 Spins up a cluster of the requested size using your AWS access.
    delete                 Terminates the specified cluster.
    wait                   Continuously checks cluster status until creation is successful.
  user
    create                 Creates user account.


-----------------------------------------------
Example:
-----------------------------------------------

  `huxley-cli user create`
  User create returns an account-specific secret_token.

  `huxley-cli cluster create --name dev --domain pandastrike.com --token goMmqfnMi6xYXqE_TuKc7g`
  Cluster create returns a cluster_id. Cluster will be created at dev.pandastrike.com.

  `huxley-cli cluster wait --token goMmqfnMi6xYXqE_TuKc7g --cluster-id l4ARsRJ6cdkSYBhkWaOWXw`
  Cluster wait will continue polling the cluster until successful creation. 

  `huxley-cli cluster delete --token goMmqfnMi6xYXqE_TuKc7g --cluster-id l4ARsRJ6cdkSYBhkWaOWXw`
  Deletes cluster, cleaning up all attached resources (e.g. private DNS).


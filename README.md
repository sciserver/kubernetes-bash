# kubernetes-bash
Shell goodies for interacting with kubernetes and helm in IDIES

To use, simply put this file somewhere and source it in your bashrc, for
example, if it is in your home directory, add this to your `~/.bashrc` file:

```bash
. kubernetes.sh
```

Then you will have access to some useful aliases and functions, and your prompt
will be modified to indicate what your working context is:

```
# select a cluster
kc

# select a namespace (if you are allowed)
kn

# list pods
kp

# get logs
kl

# do any kubernetes action in the set namespace, for example:
k get deployments
```

Note how you do not have to type the namespace, you are in a sense working
within whatever namespace (KN) was selected either with `kc` or `kn` and
indicated on your prompt (and in the context of the cluster (KC) also listed)
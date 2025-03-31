# imagepullsecret-patcher Deployment Script

This script automates the deployment of the `imagepullsecret-patcher` Helm chart to a Kubernetes cluster. The `imagepullsecret-patcher` is designed to patch image pull secrets to service accounts within the cluster.

## Prerequisites

* `zsh` shell
* `kubectl` command-line tool
* `kubectx` and `kubens` command-line tools
* `helm` command-line tool
* `aws` command-line tool
* `jq` command-line tool
* Logged into AWS CLI using `aws sso login`
* AWS credentials configured with the necessary permissions.
* The `imagepullsecret-patcher` Helm chart located in the same directory as the script.

## Usage

```bash
./imagepullsecret-patcher-deployer.sh
```

### Notes

* The script requires two inputs while executing it, kube context name and AWS Secret ID. The kube-contexts will be displayed during the execution.
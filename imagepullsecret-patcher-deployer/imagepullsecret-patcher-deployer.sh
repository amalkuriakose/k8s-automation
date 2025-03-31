#!/bin/zsh
# This script is used to deploy the imagepullsecret-patcher to bosun cluster
# The imagepullsecret-patcher is used to patch the imagepullsecret to the serviceaccount

# Get the list of contexts from kubectx and number them.
NUMBERED_CONTEXTS=$(kubectx | nl)

# Print the numbered list.
echo "Available Kubernetes Contexts:"
echo "$NUMBERED_CONTEXTS"

# Prompt the user for input.
echo "Enter the number of the context to use: "
read CHOICE

# Validate the input.
if [[ ! "$CHOICE" =~ ^[0-9]+$ ]]; then
  echo "Invalid input. Please enter a number."
  exit 1
fi

# Extract the selected context name.
SELECTED_CONTEXT=$(echo "$NUMBERED_CONTEXTS" | sed -n "${CHOICE}s/^[[:space:]]*[0-9]*[[:space:]]*//p")

# Validate that the CHOICE is within the range.
if [ -z "$SELECTED_CONTEXT" ]; then
    echo "Invalid CHOICE. Context number $CHOICE not found."
    exit 1
fi

# Setting the selected context to KUBE_CONTEXT
KUBE_CONTEXT=$SELECTED_CONTEXT
echo "Selected Kubernetes Context: $KUBE_CONTEXT"

# Check if ok to proceed with the selected context
echo "Ok to proceed with the selected context? (y/n)"
read PROCEED

if [[ "$PROCEED" != "y" ]]; then
  echo "Exiting script."
  exit 0
fi

# Set the context
echo "Setting Context to $KUBE_CONTEXT"
kubectx $KUBE_CONTEXT

if [ $? -ne 0 ]; then
  echo "Error: Failed to switch to context $KUBE_CONTEXT"
  exit 1
fi

# Set the namespace
NAMESPACE=imagepullsecret-patcher
echo "Creating namespace $NAMESPACE"
kubectl create namespace $NAMESPACE

echo "Setting namespace to $NAMESPACE"
kubens $NAMESPACE

if [ $? -ne 0 ]; then
  echo "Error: Failed to switch to namespace $NAMESPACE"
  exit 1
fi

echo "Setting AWS_CONFIG_FILE and AWS_PROFILE"
export AWS_CONFIG_FILE="./config"
export AWS_PROFILE="my-profile" # Replace the profile with your profile name

echo "checking if the AWS_CONFIG_FILE is set"
if [ -z "$AWS_CONFIG_FILE" ]; then
  echo "Error: AWS_CONFIG_FILE is not set"
  exit 1
fi

echo "AWS_CONFIG_FILE is set to $AWS_CONFIG_FILE"

echo "Checking if the AWS_PROFILE is set"
if [ -z "$AWS_PROFILE" ]; then
  echo "Error: AWS_PROFILE is not set"
  exit 1
fi

echo "AWS_PROFILE is set to $AWS_PROFILE"

echo "Enter the AWS Secret ID for docker credentials:"
read AWS_SECRET

if [ -z "$AWS_SECRET" ]; then
  echo "Error: AWS Secret ID is not set"
  exit 1
fi

echo "Fetching the docker credentials from AWS Secrets Manager"
DOCKER_USERNAME=$(aws secretsmanager get-secret-value --secret-id $AWS_SECRET --query 'SecretString' --profile $AWS_PROFILE --region us-east-1 |  jq --raw-output | jq -r '.username')
DOCKER_PASSWORD=$(aws secretsmanager get-secret-value --secret-id $AWS_SECRET --query 'SecretString' --profile $AWS_PROFILE --region us-east-1 |  jq --raw-output | jq -r '.token')

if [ -z "$DOCKER_USERNAME" ]; then
  echo "Error: Failed to fetch docker username from AWS Secrets Manager"
  exit 1
fi

if [ -z "$DOCKER_PASSWORD" ]; then
  echo "Error: Failed to fetch docker password from AWS Secrets Manager"
  exit 1
fi

echo "unsetting AWS_CONFIG_FILE and AWS_PROFILE"
unset AWS_CONFIG_FILE
unset AWS_PROFILE

echo "Installing bosun-imagepullsecret-patcher Helm chart"
helm install imagepullsecret-patcher ./imagepullsecret-patcher --set namespace=$NAMESPACE --set dockerUsername=$DOCKER_USERNAME --set dockerPassword=$DOCKER_PASSWORD

if [ $? -ne 0 ]; then
  echo "Error: Failed to deploy imagepullsecret-patcher to the $KUBE_CONTEXT"
  exit 1
fi

echo "Verify the Helm Chart installation"
helm list -A

echo "Verify the deployment using kubectl"
kubectl get all -n $NAMESPACE

echo "Verify the secrets using kubectl"
echo "Source secret:"
kubectl get secret image-pull-secret-src --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode | jq

sleep 10

echo "Target secret:"
kubectl get secret image-pull-secret --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode | jq

echo "imagepullsecret-patcher deployed successfully to the $KUBE_CONTEXT"
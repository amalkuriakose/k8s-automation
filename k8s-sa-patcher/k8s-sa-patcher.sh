#!/bin/zsh

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

echo "Selected Kubernetes Context: $SELECTED_CONTEXT"

# Check if ok to proceed with the selected context
echo "Ok to proceed with the selected context? (y/n)"
read PROCEED

if [[ "$PROCEED" != "y" ]]; then
  echo "Exiting script."
  exit 0
fi

# Set the context
echo "Setting Context to $SELECTED_CONTEXT"
kubectx $SELECTED_CONTEXT

if [ $? -ne 0 ]; then
  echo "Error: Failed to switch to context $SELECTED_CONTEXT"
  exit 1
fi

# Prompt the user for the secret name.
echo "Enter the secret name to be removed from the service accounts: "
read SECRET_NAME

# Validate the input.
if [ -z "$SECRET_NAME" ]; then
  echo "Error: Secret name cannot be empty."
  exit 1
fi

# Get all namespaces.
namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')
namespace_array=("${(@s: :)namespaces}")

# Loop through each namespace.
for namespace in "${namespace_array[@]}"; do
  # Get all service accounts in the namespace.
  service_accounts=$(kubectl get sa -n $namespace -o jsonpath='{.items[*].metadata.name}')
  service_account_array=("${(@s: :)service_accounts}")
  # Loop through each service account.
  for sa in "${service_account_array[@]}"; do
    echo "Checking service account: $sa in namespace: $namespace"
    # Check if the secret exists in the service account.
    SECRET_INDEX=$(kubectl get serviceaccount $sa -n $namespace -o json  | jq ".imagePullSecrets | map(.name == \"$SECRET_NAME\") | index(true)")
    if [ $? -ne 0 ]; then
      echo "Error: Failed to get the index of secret $SECRET_NAME in service account $sa in namespace $namespace"
      continue
    fi
    
    # If the secret exists, delete it from the service account.
    if [ "$SECRET_INDEX" != "null" ]; then
      echo "Deleting secret $SECRET_NAME from service account $sa in namespace $namespace"
      kubectl patch serviceaccount $sa -n $namespace --type='json' -p="[{\"op\": \"remove\", \"path\": \"/imagePullSecrets/$SECRET_INDEX\"}]"
      if [ $? -ne 0 ]; then
        echo "Error: Failed to delete secret $SECRET_NAME from service account $sa in namespace $namespace"
      else
        echo "Successfully deleted secret $SECRET_NAME from service account $sa in namespace $namespace"
      fi
    else
      echo "Secret $SECRET_NAME not found in service account $sa in namespace $namespace"
    fi
  done
done

echo "Completed."
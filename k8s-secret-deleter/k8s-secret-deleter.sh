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
echo "Enter the secret name to delete: "
read secret_name

# Validate the input.
if [ -z "$secret_name" ]; then
  echo "Error: Secret name cannot be empty."
  exit 1
fi

# Get all namespaces.
namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

namespace_array=("${(@s: :)namespaces}")

# Loop through each namespace.
for namespace in "${namespace_array[@]}"; do
  # Check if the secret exists in the namespace.
  if kubectl get secret $secret_name -n $namespace &>/dev/null; then
    # Delete the secret.
    kubectl delete secret $secret_name -n $namespace
    if [ $? -eq 0 ]; then
      echo "Deleted secret $secret_name in namespace $namespace."
    else
      echo "Failed to delete secret $secret_name in namespace $namespace."
    fi
  else
    echo "Secret $secret_name not found in namespace $namespace."
  fi
done

echo "Completed."
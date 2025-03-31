# Kubernetes Service Account Patcher

This shell script automates the process of removing a specified image pull secret from all service accounts across all namespaces in a Kubernetes cluster.

## Prerequisites

-   `kubectl` installed and configured to access your Kubernetes cluster.
-   `kubectx` installed (optional, but recommended for easy context switching).
-   `jq` installed for JSON processing.
-   `zsh` shell.

## Usage

1.  **Save the script:** Save the script to a file, for example, `remove-secret-from-sa.sh`.
2.  **Make it executable:** Run `chmod +x remove-secret-from-sa.sh`.
3.  **Run the script:** Execute the script using `./remove-secret-from-sa.zsh`.
4.  **Select the context:** If you have multiple Kubernetes contexts configured, the script will display a numbered list of contexts. Enter the number corresponding to the desired context.
5.  **Confirm the context:** The script will ask for confirmation before switching to the selected context. Type `y` and press Enter to proceed, or `n` to exit.
6.  **Enter the secret name:** Enter the name of the secret you want to remove from the service accounts.
7.  **Review the output:** The script will iterate through all namespaces and service accounts, displaying the progress and any errors encountered.

## Script Functionality

1.  **Context Selection:**
    -      Uses `kubectx` to list available Kubernetes contexts.
    -      Prompts the user to select a context by number.
    -      Validates the user's input.
    -      Switches to the selected context using `kubectx`.
2.  **Secret Removal:**
    -      Prompts the user to enter the name of the secret to remove.
    -      Retrieves a list of all namespaces in the cluster.
    -      For each namespace:
        -      Retrieves a list of all service accounts.
        -      For each service account:
            -      Checks if the specified secret exists in the `imagePullSecrets` of the service account using `kubectl` and `jq`.
            -      If the secret exists, it's removed using `kubectl patch`.
            -      Logs the progress and any errors.
3.  **Error Handling:**
    -      Validates user input.
    -      Checks for errors during `kubectl` commands and displays appropriate messages.
    -   Handles cases where the selected context or secret are not found.

### Example

```bash
./remove-secret-from-sa.sh
```
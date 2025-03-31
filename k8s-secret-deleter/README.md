# Kubernetes Secret Deleter Script

This shell script simplifies the process of switching Kubernetes contexts and deleting a specified secret across all namespaces.

## Prerequisites

* `kubectl` and `kubectx` must be installed and configured on your system.
* You must have the necessary permissions to switch contexts and delete secrets in your Kubernetes cluster.

## Usage

1.  **Save the script:** Save the script to a file, for example, `delete_secret.sh`.
2.  **Make it executable:** Run `chmod +x delete_secret.sh` in your terminal.
3.  **Run the script:** Execute the script by running `./delete_secret.sh`.

## Script Description

The script performs the following steps:

1.  **Lists Available Contexts:** Displays a numbered list of available Kubernetes contexts using `kubectx | nl`.
2.  **Prompts for Context Selection:** Asks the user to enter the number corresponding to the desired context.
3.  **Validates Context Input:** Checks if the input is a valid number and if the selected context exists.
4.  **Confirms Context Selection:** Asks for confirmation before switching to the selected context.
5.  **Switches Context:** Uses `kubectx` to switch to the chosen Kubernetes context.
6.  **Prompts for Secret Name:** Asks the user to enter the name of the secret to delete.
7.  **Validates Secret Name:** Checks if the secret name is not empty.
8.  **Deletes Secret Across Namespaces:**
    * Retrieves a list of all namespaces.
    * Loops through each namespace.
    * Checks if the specified secret exists in the current namespace.
    * If the secret exists, it attempts to delete it.
    * Displays messages indicating success or failure of the deletion.
    * If the secret does not exist, it displays a message indicating that the secret was not found in the namespace.
9.  **Completes:** Prints "Completed." when the script finishes.

## Example

```bash
./delete_secret.sh
```

#!/bin/bash

# ==========================================
# Azure VM Encryption at Host Configuration
# ==========================================

# Exit immediately if a command exits with a non-zero status
set -e

#!/bin/bash

# ==================================================
# Azure VM Encryption at Host Configuration
# ==================================================

# Exit immediately if a command exits with a non-zero status
set -e

# --- START: ADD THESE REGISTRATION STEPS HERE ---
echo "Registering EncryptionAtHost feature..."
az feature register --namespace Microsoft.Compute --name EncryptionAtHost --output none

echo "Registering Microsoft.Compute provider..."
az provider register --namespace Microsoft.Compute --output none

echo "Waiting for feature registration to propagate (this may take a moment)..."
az feature wait --namespace Microsoft.Compute --name EncryptionAtHost
echo "Registration complete."
echo "--------------------------------------------------------------------------------"

# Define your variables here
RESOURCE_GROUP=Cloud-Operations
VM_NAME=test-encrypt-host

# ... The rest of your existing script continues here ...

# Define your variables here
RESOURCE_GROUP="your-resource-group-name"
VM_NAME="your-vm-name"

echo "Starting configuration for VM: $VM_NAME in Resource Group: $RESOURCE_GROUP"
echo "------------------------------------------------------------------------"

# 1. Fetch current VM state
echo "Checking current VM state..."
VM_STATE=$(az vm get-instance-view \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" \
  --output tsv)

echo "Current state is: $VM_STATE"

# Check if running and deallocate, or skip if already deallocated
if [[ "$VM_STATE" == "VM running" ]]; then
    echo "VM is currently running. Deallocating the VM..."
    az vm deallocate --resource-group "$RESOURCE_GROUP" --name "$VM_NAME"
    echo "Deallocation complete."
elif [[ "$VM_STATE" == "VM deallocated" ]]; then
    echo "VM is already deallocated. Skipping deallocation step."
else
    echo "VM is in an intermediate state ($VM_STATE). Forcing deallocation to ensure safe update..."
    az vm deallocate --resource-group "$RESOURCE_GROUP" --name "$VM_NAME"
fi

echo "------------------------------------------------------------------------"

# 2. Enable Encryption at Host
echo "Enabling Encryption at Host..."
az vm update \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --set securityProfile.encryptionAtHost=true

echo "Encryption at Host enabled."
echo "------------------------------------------------------------------------"

# 3. Start the VM and fetch the new state
echo "Starting the VM..."
az vm start --resource-group "$RESOURCE_GROUP" --name "$VM_NAME"

echo "Fetching new VM state..."
NEW_VM_STATE=$(az vm get-instance-view \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" \
  --output tsv)

echo "New VM state is: $NEW_VM_STATE"
echo "------------------------------------------------------------------------"

# 4. Check the status of encryption at host
echo "Verifying Encryption at Host status..."
ENCRYPTION_STATUS=$(az vm show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$VM_NAME" \
  --query "securityProfile.encryptionAtHost" \
  --output tsv)

if [[ "$ENCRYPTION_STATUS" == "true" ]]; then
    echo "SUCCESS: Encryption at Host is confirmed as ENABLED."
else
    echo "WARNING: Encryption at Host validation failed. Please check the Azure Portal or CLI logs."
fi

echo "Script execution completed."

#!/bin/bash
# Script to create a VM instance in GCP

# Define variables
VM_NAME="my-vm"
MACHINE_TYPE="e2-standard-2"  # 2 vCPUs, 8GB memory
ZONE="us-central1-a"
IMAGE_FAMILY="ubuntu-2004-lts"
IMAGE_PROJECT="ubuntu-os-cloud"
BOOT_DISK_SIZE="10GB"
BOOT_DISK_TYPE="pd-balanced"
TAGS="http-server,https-server"
STARTUP_SCRIPT="./startup_script.sh"

# Print setup information
echo "Setting up GCP VM with the following configuration:"
echo "VM Name: $VM_NAME"
echo "Machine Type: $MACHINE_TYPE"
echo "Zone: $ZONE"
echo "Image: $IMAGE_FAMILY from $IMAGE_PROJECT"
echo "Boot Disk: $BOOT_DISK_SIZE $BOOT_DISK_TYPE"
echo "Network Tags: $TAGS"

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "Error: gcloud CLI not found. Please install the Google Cloud SDK."
    exit 1
fi

# Check if user is authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "@"; then
    echo "Error: You are not authenticated with gcloud. Please run 'gcloud auth login'."
    exit 1
fi

# Create the VM instance
echo "Creating VM instance..."
gcloud compute instances create $VM_NAME \
  --machine-type=$MACHINE_TYPE \
  --zone=$ZONE \
  --image-family=$IMAGE_FAMILY \
  --image-project=$IMAGE_PROJECT \
  --boot-disk-size=$BOOT_DISK_SIZE \
  --boot-disk-type=$BOOT_DISK_TYPE \
  --tags=$TAGS \
  --metadata-from-file=startup-script=$STARTUP_SCRIPT \
  --scopes=default

# Check if VM creation was successful
if [ $? -eq 0 ]; then
    echo "VM '$VM_NAME' created successfully in zone '$ZONE'."
    
    # Get the external IP of the VM
    EXTERNAL_IP=$(gcloud compute instances describe $VM_NAME --zone=$ZONE --format='get(networkInterfaces[0].accessConfigs[0].natIP)')
    echo "External IP: $EXTERNAL_IP"
    
    echo "You can SSH into the VM using:"
    echo "gcloud compute ssh $VM_NAME --zone=$ZONE"
else
    echo "Error: Failed to create VM."
    exit 1
fi

echo "VM setup completed."

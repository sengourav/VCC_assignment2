#!/bin/bash
# Script to set up IAM roles and permissions
# Author: Gourav Sen

set -e  # Exit immediately if a command exits with a non-zero status

# Define variables
PROJECT_ID=$(gcloud config get-value project)

# Check if project ID is available
if [ -z "$PROJECT_ID" ]; then
    echo "Error: No project ID found. Please run 'gcloud config set project YOUR_PROJECT_ID'."
    exit 1
fi

echo "Setting up IAM roles for project: $PROJECT_ID"

# Function to create a service account
create_service_account() {
    local SA_NAME=$1
    local SA_DISPLAY_NAME=$2
    local ROLES=$3

    # Check if service account already exists
    if gcloud iam service-accounts describe $SA_NAME@$PROJECT_ID.iam.gserviceaccount.com &> /dev/null; then
        echo "Service account $SA_NAME already exists."
    else
        echo "Creating service account: $SA_NAME"
        gcloud iam service-accounts create $SA_NAME \
            --display-name="$SA_DISPLAY_NAME"
    fi

    # Assign roles to the service account
    IFS=',' read -ra ROLE_ARRAY <<< "$ROLES"
    for ROLE in "${ROLE_ARRAY[@]}"; do
        echo "Assigning role $ROLE to $SA_NAME"
        gcloud projects add-iam-policy-binding $PROJECT_ID \
            --member="serviceAccount:$SA_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
            --role="$ROLE"
    done
}

# Create and set up service accounts with appropriate roles

# 1. App Service Account (for the VM instances)
echo "Setting up App Service Account..."
create_service_account "vm-app-sa" "VM Application Service Account" \
    "roles/compute.instanceAdmin.v1,roles/monitoring.viewer"

# 2. Auto-scaling Manager Service Account
echo "Setting up Auto-scaling Manager Service Account..."
create_service_account "autoscaling-mgr-sa" "Auto-scaling Manager Service Account" \
    "roles/compute.instanceAdmin.v1,roles/monitoring.metricWriter"

# 3. Security Admin Service Account
echo "Setting up Security Admin Service Account..."
create_service_account "security-admin-sa" "Security Admin Service Account" \
    "roles/iam.securityAdmin,roles/compute.securityAdmin"

# Configure custom IAM roles if needed
echo "Creating custom IAM role for app management..."
# Check if the role exists
if gcloud iam roles describe app_manager --project=$PROJECT_ID &> /dev/null; then
    echo "Custom role app_manager already exists."
else
    # Create a custom role for app management
    gcloud iam roles create app_manager --project=$PROJECT_ID \
        --title="App Manager" \
        --description="Manages application deployment without full admin rights" \
        --permissions="compute.instances.get,compute.instances.list,compute.instances.reset,compute.instances.start,compute.instances.stop,monitoring.metricDescriptors.list,monitoring.timeSeries.list"
fi

# Assign the custom role to a user (replace with actual user email)
echo "Please enter the email of the user to assign app_manager role:"
read USER_EMAIL

# Validate email format
if [[ ! "$USER_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
    echo "Invalid email format. Skipping user role assignment."
else
    echo "Assigning app_manager role to $USER_EMAIL"
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="user:$USER_EMAIL" \
        --role="projects/$PROJECT_ID/roles/app_manager"
fi

echo "IAM setup completed successfully."

# Print summary of service accounts and their roles
echo -e "\n--- IAM Setup Summary ---"
echo "Project: $PROJECT_ID"
echo "Service Accounts Created:"
echo "1. vm-app-sa@$PROJECT_ID.iam.gserviceaccount.com"
echo "2. autoscaling-mgr-sa@$PROJECT_ID.iam.gserviceaccount.com"
echo "3. security-admin-sa@$PROJECT_ID.iam.gserviceaccount.com"
echo "Custom Roles Created:"
echo "- app_manager"
echo "-------------------------"

#!/bin/bash
# Script to configure firewall rules in GCP
# Author: Gourav Sen

set -e  # Exit immediately if a command exits with a non-zero status

# Define variables
PROJECT_ID=$(gcloud config get-value project)
NETWORK="default"  # Using default network, change if needed

# Check if project ID is available
if [ -z "$PROJECT_ID" ]; then
    echo "Error: No project ID found. Please run 'gcloud config set project YOUR_PROJECT_ID'."
    exit 1
fi

echo "Setting up firewall rules for project: $PROJECT_ID"

# Function to create or update a firewall rule
create_firewall_rule() {
    local RULE_NAME=$1
    local DESCRIPTION=$2
    local DIRECTION=$3  # 'ingress' or 'egress'
    local PRIORITY=$4
    local SOURCE_RANGES=$5  # For ingress rules
    local DESTINATION_RANGES=$6  # For egress rules
    local PROTOCOL_PORTS=$7
    local TARGET_TAGS=$8
    local ACTION=$9  # 'allow' or 'deny'

    # Check if rule exists
    if gcloud compute firewall-rules describe $RULE_NAME --project=$PROJECT_ID &> /dev/null; then
        echo "Firewall rule $RULE_NAME already exists. Updating..."
        gcloud compute firewall-rules update $RULE_NAME \
            --description="$DESCRIPTION" \
            --priority=$PRIORITY \
            $([[ "$ACTION" == "allow" ]] && echo "--allow=$PROTOCOL_PORTS" || echo "--deny=$PROTOCOL_PORTS") \
            $([[ ! -z "$TARGET_TAGS" ]] && echo "--target-tags=$TARGET_TAGS")
    else
        echo "Creating firewall rule: $RULE_NAME"
        
        # Base command
        CMD="gcloud compute firewall-rules create $RULE_NAME \
            --project=$PROJECT_ID \
            --network=$NETWORK \
            --description=\"$DESCRIPTION\" \
            --priority=$PRIORITY \
            --direction=$DIRECTION"
        
        # Add action (allow/deny)
        if [ "$ACTION" == "allow" ]; then
            CMD="$CMD --allow=$PROTOCOL_PORTS"
        else
            CMD="$CMD --deny=$PROTOCOL_PORTS"
        fi
        
        # Add source/destination ranges based on direction
        if [ "$DIRECTION" == "ingress" ] && [ ! -z "$SOURCE_RANGES" ]; then
            CMD="$CMD --source-ranges=$SOURCE_RANGES"
        elif [ "$DIRECTION" == "egress" ] && [ ! -z "$DESTINATION_RANGES" ]; then
            CMD="$CMD --destination-ranges=$DESTINATION_RANGES"
        fi
        
        # Add target tags if specified
        if [ ! -z "$TARGET_TAGS" ]; then
            CMD="$CMD --target-tags=$TARGET_TAGS"
        fi
        
        # Execute the command
        eval $CMD
    fi
}

# Create necessary firewall rules

# 1. Allow SSH (port 22) from anywhere
create_firewall_rule "allow-ssh" \
    "Allow SSH access" \
    "ingress" \
    "1000" \
    "0.0.0.0/0" \
    "" \
    "tcp:22" \
    "" \
    "allow"

# 2. Allow HTTP (port 80) to instances with 'http-server' tag
create_firewall_rule "allow-http" \
    "Allow HTTP traffic" \
    "ingress" \
    "1000" \
    "0.0.0.0/0" \
    "" \
    "tcp:80" \
    "http-server" \
    "allow"

# 3. Allow HTTPS (port 443) to instances with 'https-server' tag
create_firewall_rule "allow-https" \
    "Allow HTTPS traffic" \
    "ingress" \
    "1000" \
    "0.0.0.0/0" \
    "" \
    "tcp:443" \
    "https-server" \
    "allow"

# 4. Allow internal traffic between VMs in the same network
create_firewall_rule "allow-internal" \
    "Allow internal network traffic" \
    "ingress" \
    "1000" \
    "10.128.0.0/9" \
    "" \
    "tcp:0-65535,udp:0-65535,icmp" \
    "" \
    "allow"

# 5. Deny all other ingress traffic
create_firewall_rule "deny-other-ingress" \
    "Deny all other incoming traffic" \
    "ingress" \
    "2000" \
    "0.0.0.0/0" \
    "" \
    "all" \
    "" \
    "deny"

# 6. Allow health check traffic from Google's health check systems
create_firewall_rule "allow-health-checks" \
    "Allow health check traffic" \
    "ingress" \
    "1000" \
    "35.191.0.0/16,130.211.0.0/22" \
    "" \
    "tcp" \
    "" \
    "allow"

echo "Firewall rules setup completed successfully."

# Print summary of firewall rules
echo -e "\n--- Firewall Rules Summary ---"
echo "Project: $PROJECT_ID"
echo "Network: $NETWORK"
echo "Rules created:"
echo "1. allow-ssh: Allow SSH (port 22) from anywhere"
echo "2. allow-http: Allow HTTP (port 80) to instances with 'http-server' tag"
echo "3. allow-https: Allow HTTPS (port 443) to instances with 'https-server' tag"
echo "4. allow-internal: Allow internal traffic between VMs"
echo "5. deny-other-ingress: Deny all other ingress traffic"
echo "6. allow-health-checks: Allow health check traffic"
echo "----------------------------"

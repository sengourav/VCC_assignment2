# GCP VM Auto-Scaling Setup

This repository contains scripts and configuration files for setting up a virtual machine (VM) in Google Cloud Platform (GCP) with auto-scaling capabilities and robust security measures.

## Project Overview

This project implements:
- Creation of a VM instance on GCP
- Configuration of auto-scaling policies based on CPU utilization
- Implementation of security measures:
  - IAM roles for restricted access
  - Firewall rules to control traffic

## Repository Structure

```
.
├── README.md                         # This file
├── deployment/                       # Deployment scripts
│   ├── vm_setup.sh                   # VM creation script
│   └── startup_script.sh             # VM startup commands
├── auto-scaling/                     # Auto-scaling configurations
│   ├── instance_template.yaml        # Instance template configuration
│   └── autoscaling_config.yaml       # Auto-scaling policy configuration
└── security/                         # Security configurations
    ├── iam_setup.sh                  # IAM roles and permissions setup
    └── firewall_rules.sh             # Firewall rules configuration
```

## Prerequisites

- Google Cloud Platform account
- gcloud CLI installed and configured
- Appropriate GCP project permissions

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/gcp-vm-autoscaling.git
cd gcp-vm-autoscaling
```

### 2. VM Deployment

```bash
# Make the scripts executable
chmod +x deployment/vm_setup.sh
chmod +x deployment/startup_script.sh

# Execute the VM setup script
./deployment/vm_setup.sh
```

### 3. Auto-Scaling Configuration

```bash
# Create an instance template
gcloud compute instance-templates create-with-container my-instance-template \
  --config=auto-scaling/instance_template.yaml

# Create a managed instance group with auto-scaling
gcloud compute instance-groups managed create my-mig \
  --config=auto-scaling/autoscaling_config.yaml
```

### 4. Security Setup

```bash
# Make the scripts executable
chmod +x security/iam_setup.sh
chmod +x security/firewall_rules.sh

# Set up IAM roles and permissions
./security/iam_setup.sh

# Configure firewall rules
./security/firewall_rules.sh
```

## Configuration Details

### VM Instance

- Machine Type: General-purpose (2 CPU cores, 10 GB RAM)
- Operating System: Ubuntu (latest version)
- Boot Disk: Balanced Persistent Disk (pd-balanced) with 10 GB space
- Network: HTTP and HTTPS traffic enabled

### Auto-scaling

- Scaling metric: CPU utilization
- Target utilization threshold: 70%
- Minimum instances: 1
- Maximum instances: 5

### Security

- IAM roles with principle of least privilege
- Firewall rules for controlled access:
  - Inbound SSH (TCP 22)
  - HTTP (TCP 80) 
  - HTTPS (TCP 443)

## Architecture

The deployment consists of:
- VM instances managed under an auto-scaling group
- IAM roles defining access control
- Firewall rules regulating traffic flow

## Troubleshooting

If you encounter issues:
1. Check GCP console logs
2. Verify project permissions
3. Ensure gcloud CLI is properly configured

## License

[MIT License](LICENSE)

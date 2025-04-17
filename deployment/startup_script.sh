#!/bin/bash
# Startup script for VM instance
# This script runs when the VM instance first starts

# Update package information
apt-get update

# Install Apache web server
apt-get install -y apache2

# Enable and start Apache service
systemctl enable apache2
systemctl start apache2

# Install monitoring agent for auto-scaling metrics
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

# Create a simple web page
cat > /var/www/html/index.html << 'EOL'
<!DOCTYPE html>
<html>
<head>
    <title>GCP Auto-Scaling Demo</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        h1 {
            color: #4285f4;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>GCP Auto-Scaling Demo</h1>
        <p>This server is part of an auto-scaling instance group.</p>
        <p>Server hostname: <strong>$(hostname)</strong></p>
        <p>Server IP: <strong>$(hostname -I | awk '{print $1}')</strong></p>
        <p>Current time: <strong>$(date)</strong></p>
    </div>
</body>
</html>
EOL

# Install stress tool for testing CPU load (for auto-scaling demo)
apt-get install -y stress-ng

# Log the completion
echo "Startup script completed successfully at $(date)" >> /var/log/startup-script.log

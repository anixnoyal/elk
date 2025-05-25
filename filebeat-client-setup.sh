#!/bin/bash

# Exit on error
set -e

# Ensure script runs with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

# Variables (replace <elk-server-ip> with the actual ELK server IP)
ELK_SERVER_IP="<elk-server-ip>"
LOGSTASH_PORT=5044

echo "Starting Filebeat setup on client machine..."

# Step 1: Add Elastic repository
echo "Adding Elastic repository..."
cat <<EOF >/etc/yum.repos.d/elasticsearch.repo
[elasticsearch-8.x]
name=Elasticsearch repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

# Step 2: Install Filebeat
echo "Installing Filebeat..."
dnf install -y filebeat

# Step 3: Ensure SSL certificate is present
echo "Checking for SSL certificate..."
if [ ! -f /etc/pki/tls/certs/logstash-forwarder.crt ]; then
  echo "Please copy logstash-forwarder.crt from ELK server to /etc/pki/tls/certs/"
  exit 1
fi

# Step 4: Configure Filebeat
echo "Configuring Filebeat..."
cat <<EOF >/etc/filebeat/filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log
    - /var/log/secure
    - /var/log/messages

output.logstash:
  hosts: ["$ELK_SERVER_IP:$LOGSTASH_PORT"]
  ssl.certificate_authorities: ["/etc/pki/tls/certs/logstash-forwarder.crt"]

# Disable Elasticsearch output
output.elasticsearch:
  enabled: false
EOF

# Step 5: Enable system module
echo "Enabling Filebeat system module..."
filebeat modules enable system

# Step 6: Start and enable Filebeat
echo "Starting Filebeat..."
systemctl start filebeat
systemctl enable filebeat

echo "Filebeat setup complete!"
echo "Logs are being sent to $ELK_SERVER_IP:$LOGSTASH_PORT"
echo "Verify logs in Kibana at http://$ELK_SERVER_IP:5601"
#!/bin/bash

# Add Elastic's signing key
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

# Add Elastic's YUM repository
cat <<EOF > /etc/yum.repos.d/elasticsearch.repo
[elasticsearch-8.x]
name=Elasticsearch repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

# Install Java (OpenJDK 11)
yum install -y java-11-openjdk-devel

# Install Elasticsearch, Logstash, Kibana
yum install -y elasticsearch logstash kibana

# Adjusting the system configuration for Elasticsearch
# Increase max file descriptors
ulimit -n 65535

# Increase max virtual memory
sysctl -w vm.max_map_count=262144

# Start and enable services
systemctl start elasticsearch
systemctl enable --now elasticsearch

systemctl start logstash
systemctl enable --now logstash

systemctl start kibana
systemctl enable --now kibana

# Print status
echo "Installation complete. Here's the status of the services:"
systemctl status elasticsearch
systemctl status logstash
systemctl status kibana

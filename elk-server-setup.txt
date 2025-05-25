#!/bin/bash

# Exit on error
set -e

# Ensure script runs with sudo
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or with sudo"
  exit 1
fi

# Variables
ELK_SERVER_IP=$(hostname -I | awk '{print $1}')
LOGSTASH_PORT=5044
KIBANA_PORT=5601
ELASTICSEARCH_PORT=9200

echo "Starting ELK Stack setup on RHEL 9 server..."

# Step 1: Install Java (OpenJDK 11)
echo "Installing Java..."
dnf install -y java-11-openjdk
java -version

# Step 2: Add Elastic repository
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

# Step 3: Install Elasticsearch
echo "Installing Elasticsearch..."
dnf install -y elasticsearch
sed -i 's/#network.host: 192.168.0.1/network.host: 0.0.0.0/' /etc/elasticsearch/elasticsearch.yml
sed -i 's/#http.port: 9200/http.port: 9200/' /etc/elasticsearch/elasticsearch.yml
echo "discovery.type: single-node" >> /etc/elasticsearch/elasticsearch.yml
systemctl start elasticsearch
systemctl enable elasticsearch
echo "Waiting for Elasticsearch to start..."
sleep 10
curl -s http://localhost:9200 >/dev/null && echo "Elasticsearch is running" || { echo "Elasticsearch failed to start"; exit 1; }

# Step 4: Install Kibana
echo "Installing Kibana..."
dnf install -y kibana
sed -i 's/#server.port: 5601/server.port: 5601/' /etc/kibana/kibana.yml
sed -i 's/#server.host: "localhost"/server.host: "0.0.0.0"/' /etc/kibana/kibana.yml
sed -i 's/#elasticsearch.hosts: \["http:\/\/localhost:9200"\]/elasticsearch.hosts: \["http:\/\/localhost:9200"\]/' /etc/kibana/kibana.yml
systemctl start kibana
systemctl enable kibana

# Step 5: Install Logstash
echo "Installing Logstash..."
dnf install -y logstash
mkdir -p /etc/pki/tls/certs /etc/pki/tls/private
openssl req -x509 -days 3650 -batch -nodes -newkey rsa:2048 \
  -keyout /etc/pki/tls/private/logstash-forwarder.key \
  -out /etc/pki/tls/certs/logstash-forwarder.crt

# Step 6: Configure Logstash pipeline
echo "Configuring Logstash pipeline..."
cat <<EOF >/etc/logstash/conf.d/logstash.conf
input {
  beats {
    port => $LOGSTASH_PORT
    ssl => true
    ssl_certificate => "/etc/pki/tls/certs/logstash-forwarder.crt"
    ssl_key => "/etc/pki/tls/private/logstash-forwarder.key"
  }
}
filter {
  grok {
    match => { "message" => "%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
  }
}
output {
  elasticsearch {
    hosts => ["http://localhost:9200"]
    index => "filebeat-%{+YYYY.MM.dd}"
  }
  stdout { codec => rubydebug }
}
EOF

# Step 7: Test and start Logstash
echo "Testing Logstash configuration..."
/usr/share/logstash/bin/logstash --config.test_and_exit -f /etc/logstash/conf.d/logstash.conf
systemctl start logstash
systemctl enable logstash

# Step 8: Configure firewall
echo "Configuring firewall..."
firewall-cmd --permanent --add-port=$ELASTICSEARCH_PORT/tcp
firewall-cmd --permanent --add-port=$KIBANA_PORT/tcp
firewall-cmd --permanent --add-port=$LOGSTASH_PORT/tcp
firewall-cmd --reload

echo "ELK Stack setup complete!"
echo "Access Kibana at http://$ELK_SERVER_IP:5601"
echo "Copy /etc/pki/tls/certs/logstash-forwarder.crt to client machine"
echo "Elasticsearch is listening on port $ELASTICSEARCH_PORT"
echo "Logstash is listening on port $LOGSTASH_PORT"
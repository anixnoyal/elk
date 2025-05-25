# Verify Elasticsearch is running
sudo systemctl status elasticsearch

# Check cluster health (replace <elastic-password> with elastic user password)
curl -u elastic:<elastic-password> -X GET "http://localhost:9200/_cluster/health?pretty"

# Generate enrollment token for Kibana (prompts for elastic password)
sudo /usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana --url http://localhost:9200

# Generate SSL certificate for Elasticsearch (if not already done)
sudo /usr/share/elasticsearch/bin/elasticsearch-certutil ca --out /etc/elasticsearch/elastic-stack-ca.p12 --pass ""
sudo /usr/share/elasticsearch/bin/elasticsearch-certutil cert --ca /etc/elasticsearch/elastic-stack-ca.p12 --out /etc/elasticsearch/elastic-certificates.p12 --pass ""
sudo chown elasticsearch:elasticsearch /etc/elasticsearch/*.p12
sudo chmod 640 /etc/elasticsearch/*.p12

# Configure Elasticsearch for SSL (edit /etc/elasticsearch/elasticsearch.yml)
sudo bash -c 'cat <<EOF >>/etc/elasticsearch/elasticsearch.yml
xpack.security.http.ssl.enabled: true
xpack.security.http.ssl.keystore.path: /etc/elasticsearch/elastic-certificates.p12
xpack.security.http.ssl.keystore.password: ""
EOF'

# Restart Elasticsearch
sudo systemctl restart elasticsearch

# Install Kibana
sudo dnf install -y kibana

# Reset kibana_system password
sudo /usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system --batch

# Configure Kibana (edit /etc/kibana/kibana.yml, replace <kibana_system_password>)
sudo bash -c 'cat <<EOF >/etc/kibana/kibana.yml
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["https://localhost:9200"]
elasticsearch.username: "kibana_system"
elasticsearch.password: "<kibana_system_password>"
elasticsearch.requestTimeout: 60000
elasticsearch.ssl.certificateAuthorities: ["/etc/elasticsearch/elastic-stack-ca.p12"]
EOF'

# Open firewall ports
sudo firewall-cmd --permanent --add-port=9200/tcp
sudo firewall-cmd --permanent --add-port=5601/tcp
sudo firewall-cmd --reload

# Start and enable Kibana
sudo systemctl start kibana
sudo systemctl enable kibana

# Access Kibana at https://<elk-server-ip>:5601 and use enrollment token
# Log in with username: elastic and password: <elastic-password>

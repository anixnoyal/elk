#!/bin/bash

# Download and install the public signing key
rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

# Create the Elasticsearch repository
cat > /etc/yum.repos.d/elasticsearch.repo << EOL
[elasticsearch-8.x]
name=Elasticsearch repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOL

# Install Elasticsearch
yum install elasticsearch -y

# Enable and start Elasticsearch
systemctl enable --now elasticsearch

#!/bin/bash

# Create the Logstash repository
cat > /etc/yum.repos.d/logstash.repo << EOL
[logstash-8.x]
name=Elastic repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOL

# Install Logstash
yum install logstash -y

# Enable and start Logstash
systemctl enable --now logstash


#!/bin/bash

# Create the Kibana repository
cat > /etc/yum.repos.d/kibana.repo << EOL
[kibana-8.x]
name=Kibana repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOL

# Install Kibana
yum install kibana -y

# Enable and start Kibana
systemctl enable --now kibana


systemctl restart elasticsearch
systemctl restart logstash
systemctl restart kibana

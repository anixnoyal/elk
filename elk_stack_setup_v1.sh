# install prerequisites 

rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

cat > /etc/yum.repos.d/elasticsearch.repo <<EOF
[elasticsearch-8.x]
name=Elasticsearch repository for 8.x packages
baseurl=https://artifacts.elastic.co/packages/8.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOF

systemctl stop firewalls
systemctl disable firewalld


yum update -y
yum install nc mlocate java-11-openjdk-devel -y

# Install Elasticsearch - master 01


#change the hostnames
Server_name="master1"
echo "$Server_name" | sudo tee /etc/hostname
hostnamectl set-hostname $Server_name

#HTTP/INSECURE
yum install elasticsearch

cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.original 
grep -v -e '^[[:space:]]*#' -e '^$' /etc/elasticsearch/elasticsearch.yml.original  > /etc/elasticsearch/elasticsearch.yml

vi /etc/elasticsearch/elasticsearch.yml
xpack.security.enabled: false


#HTTPS/SECURE
cluster.name: my-cluster-name  # Choose a name for your cluster
node.name: node-1  # Change for each server: node-1, node-2, node-3
network.host: 0.0.0.0
discovery.zen.ping.unicast.hosts: ["server1_ip", "server2_ip", "server3_ip"]
discovery.zen.minimum_master_nodes: 2  # Majority of master eligible nodes

#JVM MEMORY SETUP

cp /etc/elasticsearch/jvm.options /etc/elasticsearch/jvm.options.original
grep -v -e '^[[:space:]]*#' -e '^$' /etc/elasticsearch/jvm.options.original  > /etc/elasticsearch/jvm.options

vi /etc/elasticsearch/jvm.options
-Xms1g
-Xmx1g

systemctl enable --now elasticsearch 
systemctl status elasticsearch

# VERIFY elasticsearch service Connection 
curl http://localhost:9200

# INSTALL logstash server

#change the hostnames
Server_name="logstash1"
echo "$Server_name" | sudo tee /etc/hostname
hostnamectl set-hostname $Server_name

yum install logstash -y

vi /etc/logstash/conf.d/logstash.conf

input {
  beats {
    port => 5044
  }
}

filter {
  if [host] == "192.168.31.249" {
    mutate { add_field => { "index_name" => "192.168.31.249_index" } }
  }  
}

output {
  elasticsearch {
    hosts => ["192.168.31.249:9200"]
    index => "%{index_name}"
  }
}


systemctl enable --now logstash
systemctl status logstash

# INSTALL kibana

Server_name="kibana1"
echo "$Server_name" | sudo tee /etc/hostname
hostnamectl set-hostname $Server_name

yum install kibana -y 

cp /etc/kibana/kibana.yml /etc/kibana/kibana.yml.original 
grep -v -e '^[[:space:]]*#' -e '^$' /etc/kibana/kibana.yml.original > /etc/kibana/kibana.yml

vi /etc/kibana/kibana.yml 
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://server1_ip:9200", "http://server2_ip:9200", "http://server3_ip:9200"]

systemctl enable --now kibana
systemctl status kibana


# HOST filebeat and metricbeat installation
Server_name="elk-host1"
echo "$Server_name" | sudo tee /etc/hostname
hostnamectl set-hostname $Server_name


yum install metricbeat filebeat -y

cp /etc/metricbeat/metricbeat.yml /etc/metricbeat/metricbeat.yml.original 
grep -v -e '^[[:space:]]*#' -e '^$' /etc/metricbeat/metricbeat.yml.original > /etc/metricbeat/metricbeat.yml

vi /etc/metricbeat/metricbeat.yml
output.logstash:
  hosts: ["your_logstash_server:5044"]

systemctl enable --now metricbeat
systemctl status metricbeat


cp /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.original 
grep -v -e '^[[:space:]]*#' -e '^$' /etc/filebeat/filebeat.yml.original > /etc/filebeat/filebeat.yml

vi /etc/filebeat/filebeat.yml
output.logstash:
  hosts: ["your_logstash_server:5044"]

systemctl enable --now filebeat
systemctl status filebeat

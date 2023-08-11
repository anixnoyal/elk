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

#HTTP/INSECURE
yum install elasticsearch

mv /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.original 
cat /etc/elasticsearch/elasticsearch.yml.original | grep -v ^# > /etc/elasticsearch/elasticsearch.yml

vi /etc/elasticsearch/elasticsearch.yml
xpack.security.enabled: false


#HTTPS/SECURE
cluster.name: my-cluster-name  # Choose a name for your cluster
node.name: node-1  # Change for each server: node-1, node-2, node-3
network.host: 0.0.0.0
discovery.zen.ping.unicast.hosts: ["server1_ip", "server2_ip", "server3_ip"]
discovery.zen.minimum_master_nodes: 2  # Majority of master eligible nodes

#JVM MEMORY SETUP
mv /etc/elasticsearch/jvm.options /etc/elasticsearch/jvm.options.original 
cat /etc/elasticsearch/jvm.options.original | grep -v ^# > /etc/elasticsearch/jvm.options

vi /etc/elasticsearch/jvm.options
-Xms1g
-Xmx1g

systemctl enable --now elasticsearch 
systemctl status elasticsearch

# VERIFY elasticsearch service Connection 
curl http://localhost:9200

# INSTALL logstash server

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

yum install kibana -y 

mv /etc/kibana/kibana.yml /etc/kibana/kibana.yml.original 
cat /etc/kibana/kibana.yml.original  | grep -v -e "^#" -e "^$" > /etc/kibana/kibana.yml 

vi /etc/kibana/kibana.yml 
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://server1_ip:9200", "http://server2_ip:9200", "http://server3_ip:9200"]

systemctl enable --now kibana
systemctl status kibana




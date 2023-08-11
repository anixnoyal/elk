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

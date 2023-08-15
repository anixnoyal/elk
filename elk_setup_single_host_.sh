### install prerequisites 
# change hostname
#change the hostnames
#server_name="master-01"
#echo "$server_name" | tee /etc/hostname
#hostnamectl set-hostname $server_name

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

systemctl stop firewalld
systemctl disable firewalld

yum update -y
yum install bc nc mlocate java-11-openjdk-devel -y

### INSTALL elasticsearch

yum install elasticsearch -y

cp /etc/elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml.original 
grep -v -e '^[[:space:]]*#' -e '^$' /etc/elasticsearch/elasticsearch.yml.original  > /etc/elasticsearch/elasticsearch.yml

# path to your elasticsearch.yml
CONFIG_FILE="/etc/elasticsearch/elasticsearch.yml"
NEW_CLUSTER_NAME="elasticsearch-$(date +%Y%m%d)"

# Delete the line containing text
sed -i '/xpack.security.enabled/d' "$CONFIG_FILE"
echo "xpack.security.enabled: false" >> "$CONFIG_FILE"
sed -i '/cluster.name/d' "$CONFIG_FILE"
echo "cluster.name: $NEW_CLUSTER_NAME" >> "$CONFIG_FILE"

#JVM MEMORY SETUP

cp /etc/elasticsearch/jvm.options /etc/elasticsearch/jvm.options.original
grep -v -e '^[[:space:]]*#' -e '^$' /etc/elasticsearch/jvm.options.original  > /etc/elasticsearch/jvm.options

CONFIG_FILE="/etc/elasticsearch/jvm.options"
sed -i '/-Xms/d' "$CONFIG_FILE"
sed -i '/-Xmx/d' "$CONFIG_FILE"
TOTAL_MEMORY_KB=$(free -k | awk '/Mem:/ {print $2}')
ONE_THIRD_MEMORY_KB=$(echo "$TOTAL_MEMORY_KB / 3" | bc)
ONE_THIRD_MEMORY_MB=$(echo "$ONE_THIRD_MEMORY_KB / 1024" | bc)
echo "-Xms${ONE_THIRD_MEMORY_MB}m" >> "$CONFIG_FILE"
echo "-Xmx${ONE_THIRD_MEMORY_MB}m" >> "$CONFIG_FILE"

systemctl enable elasticsearch 
systemctl start elasticsearch 
systemctl status elasticsearch

# VERIFY elasticsearch service Connection 
curl http://localhost:9200


### install logstash
yum install logstash -y

logstash_source="anix-app"

echo "
input {
  beats {
    port => 5044
  }
}

filter {
  if [source] == \"${logstash_source}\" {
    mutate {
      add_field => { "app_name" => \"${logstash_source}\" }
    }
  }
}

output {
  if [source] == \"${logstash_source}\" {
    elasticsearch {
      hosts => [\"localhost:9200\"]
      index => \"${logstash_source}-%{+YYYY.MM}\"
    }
  }
}
" > /etc/logstash/conf.d/beats.conf

systemctl enable logstash
systemctl start logstash
#tail -f /var/log/logstash/logstash-plain.log
systemctl status logstash


### INSTALL kibana
yum install kibana -y 

cp /etc/kibana/kibana.yml /etc/kibana/kibana.yml.original 
grep -v -e '^[[:space:]]*#' -e '^$' /etc/kibana/kibana.yml.original > /etc/kibana/kibana.yml


CONFIG_FILE="/etc/kibana/kibana.yml"
sed -i '/server.host/d' "$CONFIG_FILE"
sed -i '/elasticsearch.hosts:/d' "$CONFIG_FILE"
echo "server.host: "0.0.0.0"" >> "$CONFIG_FILE"
echo "elasticsearch.hosts: [\"http://localhost:9200\"]" >> "$CONFIG_FILE"


systemctl enable kibana
systemctl start kibana
systemctl status kibana

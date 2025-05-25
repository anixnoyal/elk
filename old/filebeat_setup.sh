# change hostname
#change the hostnames
#server_name="client-host-01"
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
yum install filebeat -y
filebeat modules enable system

cp /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.original 
grep -v -e '^[[:space:]]*#' -e '^$' /etc/filebeat/filebeat.yml.original > /etc/filebeat/filebeat.yml

beat_source_id="anix-app"
elk_logstash_server="192.168.31.202:5044"
echo "
filebeat.inputs:
- type: filestream
  id: ${beat_source_id}
  paths:
    - /var/log/messages
    - /var/log/*.log
  fields:
    source: ${beat_source_id}
  fields_under_root: true

output.logstash:
  hosts: "${elk_logstash_server}"

filebeat.config.modules:
  path: \${path.config}/modules.d/*.yml
  reload.enabled: ture
"> /etc/filebeat/filebeat.yml


sed -i 's/enabled: false/enabled: true/g'  /etc/filebeat/modules.d/system.yml

systemctl enable filebeat
systemctl start filebeat
systemctl status filebeat

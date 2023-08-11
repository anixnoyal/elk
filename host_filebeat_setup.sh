# HOST filebeat and metricbeat installation

Server_name="elk-host1"
echo "$Server_name" | sudo tee /etc/hostname
hostnamectl set-hostname $Server_name

yum install filebeat -y

cp /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.original 
grep -v -e '^[[:space:]]*#' -e '^$' /etc/filebeat/filebeat.yml.original > /etc/filebeat/filebeat.yml

vi /etc/filebeat/filebeat.yml
output.logstash:
  hosts: ["your_elasticsearch_server:9200"]
#or
  hosts: ["your_logstash_server:5044"]

filebeat setup -e

systemctl enable --now filebeat
systemctl status filebeat

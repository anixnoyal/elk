# HOST filebeat and metricbeat installation
Server_name="elk-host1"
echo "$Server_name" | sudo tee /etc/hostname
hostnamectl set-hostname $Server_name

yum install metricbeat -y

cp /etc/metricbeat/metricbeat.yml /etc/metricbeat/metricbeat.yml.original 
grep -v -e '^[[:space:]]*#' -e '^$' /etc/metricbeat/metricbeat.yml.original > /etc/metricbeat/metricbeat.yml

vi /etc/metricbeat/metricbeat.yml
output.logstash:
  hosts: ["your_elasticsearch_server:9200"]
#or
  hosts: ["your_logstash_server:5044"]

metricbeat setup -e

systemctl enable --now metricbeat
systemctl status metricbeat
# HOST filebeat and metricbeat installation

Server_name="elk-host1"
echo "$Server_name" | sudo tee /etc/hostname
hostnamectl set-hostname $Server_name

yum install filebeat -y

cp /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.original 
grep -v -e '^[[:space:]]*#' -e '^$' /etc/filebeat/filebeat.yml.original > /etc/filebeat/filebeat.yml

vi /etc/filebeat/filebeat.yml

filebeat.inputs:
- type: filestream
  id: my-filestream-id
  enabled: true
  paths:
    - /var/log/*.log
filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: ture

setup.kibana:
  host: "192.168.31.244:5601"
output.elasticsearch:
  hosts: ["192.168.31.249:9200"]
#output.logstash:
#  hosts: ["192.168.31.234:5044"]

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded

filebeat setup -e

systemctl enable --now filebeat
systemctl status filebeat

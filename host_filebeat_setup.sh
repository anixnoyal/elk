# HOST filebeat and metricbeat installation

Server_name="elk-host1"
echo "$Server_name" | sudo tee /etc/hostname
hostnamectl set-hostname $Server_name

yum install filebeat -y

cp /etc/filebeat/filebeat.yml /etc/filebeat/filebeat.yml.original 
grep -v -e '^[[:space:]]*#' -e '^$' /etc/filebeat/filebeat.yml.original > /etc/filebeat/filebeat.yml

filebeat modules enable system

vi /etc/filebeat/filebeat.yml
#** add filebeat.yml config here**#

vi /etc/filebeat/modules.d/system.yml
  syslog:
    enabled: true
  auth:
    enabled: true

systemctl enable --now filebeat
systemctl status filebeat

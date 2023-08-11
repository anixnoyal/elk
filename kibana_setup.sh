# INSTALL kibana

Server_name="kibana-01"
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

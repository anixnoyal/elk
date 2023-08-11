# INSTALL logstash server

#change the hostnames
Server_name="logstash-01"
echo "$Server_name" | sudo tee /etc/hostname
hostnamectl set-hostname $Server_name

yum install logstash -y

vi /etc/logstash/conf.d/logstash.conf

input {
  beats {
    port => 5044
  }
}

output {
  elasticsearch {
    hosts => ["elasticserver_ip_or_fqdn:9200"]
   }
}

systemctl enable --now logstash
systemctl status logstash

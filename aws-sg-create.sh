aws ec2 create-security-group --group-name ELKStackSG --description "ELK Stack Security Group"


aws ec2 create-tags --resources sg-0123456789abcdef0 --tags Key=Name,Value=ELKStack Key=Environment,Value=Production



TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
INSTANCE_ID=`curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id`
echo $INSTANCE_ID

aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" --output text | awk '{print $2 " : " $5}'


aws ec2 create-security-group --group-name ELKStackSG --description "ELK Stack Security Group"


aws ec2 create-tags --resources sg-0123456789abcdef0 --tags Key=Name,Value=ELKStack Key=Environment,Value=Production

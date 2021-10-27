#!/bin/sh -e

TEAMNAME=$(whoami)
TSUNG_AMI=ami-0085826a91a6d1ec3

if [ $# -eq 0 ]; then
    instance_type=t3.micro
elif [ $# -eq 1 ]; then
    instance_type=$1
else
    echo "Usage $0 [INSTANCE_TYPE]"
    exit 1
fi


result=$(aws ec2 run-instances \
    --image-id=$TSUNG_AMI \
    --instance-type=$instance_type \
    --key-name=$TEAMNAME \
    --monitoring=Enabled=True \
    --security-groups='["tsung"]' \
    --tag-specifications='[{"ResourceType":"instance","Tags":[{"Key":"Name","Value":"tsung-'$TEAMNAME'"}]},{"ResourceType":"volume","Tags":[{"Key":"Name","Value":"tsung-'$TEAMNAME'"}]}]')

id=$(echo $result | jq -r '.Instances[].InstanceId')

echo "Instance $id is launching. Obtaining IP address..."
sleep 1
public_ip=$(aws ec2 describe-instances --filters Name=instance-id,Values=$id | jq -r .Reservations[].Instances[].PublicIpAddress)

echo -e "SSH\n---\nssh ec2-user@$public_ip\n"
echo -e "HTTP\n----\nhttp://$public_ip"

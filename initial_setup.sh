#!/bin/bash

# Variables
AWS_DIR="/opt/aws"
NGINX_DIR="/var/www/html/"
BUCKET_NAME="${bucket_name}"
HOSTNAME="$(hostname)"

# Required packages 

apt update
apt upgrade -y 

#apt-get -y install python3 python3-pip build-essential libssl-dev libffi-dev python3-dev python3-venv unzip curl

apt-get -y install nginx curl unzip php php-mysql mysql-client

systemctl start nginx
systemctl enable nginx

# Installing AWS CLI 

mkdir -p $AWS_DIR

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o $AWS_DIR/awscliv2.zip
unzip $AWS_DIR/awscliv2.zip -d $AWS_DIR
$AWS_DIR/aws/install

# Downloading required files 

/usr/local/bin/aws s3 cp s3://$BUCKET_NAME/index.html $NGINX_DIR/index.html
echo $HOSTNAME >> $NGINX_DIR/index.html

echo "ubuntu" | passwd ubuntu # to delete later, only for tty access
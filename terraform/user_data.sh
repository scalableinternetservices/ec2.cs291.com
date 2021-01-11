#!/bin/bash
yum update -y
yum install -y emacs-nox gcc git httpd-tools jq libffi-devel openssl-devel python3 python3-devel
pip3 install --upgrade pip
/usr/local/bin/pip install PyJWT==1.6.1 awsebcli --upgrade
amazon-linux-extras install ruby2.6
gem install jwt

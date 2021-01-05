#!/bin/bash
yum update -y
yum install -y emacs-nox gcc git httpd-tools libffi-devel openssl-devel python3 python3-devel
amazon-linux-extras install ruby2.6
pip3 install --upgrade pip
/usr/local/bin/pip install awsebcli --upgrade

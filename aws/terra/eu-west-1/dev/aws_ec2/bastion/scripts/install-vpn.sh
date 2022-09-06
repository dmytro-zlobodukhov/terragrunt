#!/bin/bash

sudo yum -y update

gpg --keyserver hkp://keyserver.ubuntu.com --recv-keys 7568D9BB55FF9E5287D586017AE645C0CF8E292A
gpg --armor --export 7568D9BB55FF9E5287D586017AE645C0CF8E292A > key.tmp; sudo rpm --import key.tmp; rm -f key.tmp

sudo tee /etc/yum.repos.d/mongodb-org-4.4.repo << EOF
[mongodb-org-4.2]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/7/mongodb-org/4.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
EOF

sudo tee /etc/yum.repos.d/pritunl.repo << EOF
[pritunl]
name=Pritunl Repository
baseurl=https://repo.pritunl.com/stable/yum/oraclelinux/7/
gpgcheck=1
enabled=1
EOF

sudo yum -y install oracle-epel-release-el7
sudo yum-config-manager --enable ol7_developer_epel

sudo yum -y remove iptables-services
sudo systemctl stop firewalld.service
sudo systemctl disable firewalld.service

sudo yum -y install pritunl mongodb-org htop
sudo systemctl enable mongod pritunl
sudo systemctl start mongod pritunl

sudo yum swap openvpn pritunl-openvpn
#!/bin/bash

yum install redis -y

cp /etc/redis.conf{,.original}
sed -i 's/daemonize no/daemonize yes/' /etc/redis.conf 
sed -i 's/bind 127.0.0.1/bind 0.0.0.0/g' /etc/redis.conf 
sed -i 's/timeout 0/timeout 30/' /etc/redis.conf 
sed -i 's/tcp-keepalive 0/tcp-keepalive 60/' /etc/redis.conf 
sed -i 's/# requirepass foobared/requirepass passw0rd/g' /etc/redis.conf 
sed -i 's/# maxclients 10000/maxclients 10000/' /etc/redis.conf 


cat >> /etc/sysctl.conf <<EOF
# Set up for Redis
vm.overcommit_memory = 1
EOF

sysctl vm.overcommit_memory=1

systemctl enable redis
systemctl start redis

iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 6379 -j ACCEPT
service iptables save


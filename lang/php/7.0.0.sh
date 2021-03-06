#!/bin/bash

groupadd -g 80 www
adduser -o --home /www --uid 80 --gid 80 -c "Web Application" www

#yum install -y gcc gcc-c++ make patch automake autoconf \
yum install -y systemd-devel libacl-devel curl-devel libmcrypt-devel mhash-devel gd-devel libjpeg-devel libpng-devel libXpm-devel libxml2-devel libxslt-devel openssl-devel recode-devel 
#yum install openldap-devel net-snmp-devel

yum localinstall -y http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
yum install mysql-community-devel -y

yum install -y http://yum.postgresql.org/9.4/redhat/rhel-7-x86_64/pgdg-centos94-9.4-1.noarch.rpm
yum install -y postgresql94-devel

cd /usr/local/src/
wget https://downloads.php.net/~ab/php-7.0.0RC3.tar.gz

if [ -s php-7.0.0RC3.tar.gz ]; then

tar zxf php-7.0.0RC3.tar.gz
cd php-7.0.0RC3

./configure --prefix=/srv/php-7.0.0RC3 \
--with-config-file-path=/srv/php-7.0.0RC3/etc \
--with-config-file-scan-dir=/srv/php-7.0.0RC3/etc/conf.d \
--enable-fpm \
--enable-opcache \
--with-fpm-user=www \
--with-fpm-group=www \
--with-fpm-systemd \
--with-fpm-acl \
--disable-cgi \
--with-pear \
--with-curl \
--with-gd \
--with-jpeg-dir \
--with-png-dir \
--with-freetype-dir \
--with-zlib-dir \
--with-iconv \
--with-mcrypt \
--with-mhash \
--with-pdo-mysql \
--with-mysql-sock=/var/lib/mysql/mysql.sock \
--with-mysqli=/usr/bin/mysql_config \
--with-pdo-pgsql=/usr/pgsql-9.4 \
--with-openssl \
--with-xsl \
--with-recode \
--with-tsrm-pthreads \
--enable-sockets \
--enable-soap \
--enable-mbstring \
--enable-exif \
--enable-gd-native-ttf \
--enable-zip \
--enable-xml \
--enable-bcmath \
--enable-calendar \
--enable-shmop \
--enable-dba \
--enable-wddx \
--enable-shmop \
--enable-sysvsem \
--enable-sysvshm \
--enable-sysvmsg \
--enable-pcntl \
--enable-maintainer-zts \
--disable-debug

fi

[[ $? -ne 0 ]] && echo "Error: configure" &&  exit $?

make -j12

[[ $? -ne 0 ]] && echo "Error: make" &&  exit $?

if [ $(id -u) != "0" ]; then
    sudo make install
else
	make install
fi

[[ $? -ne 0 ]] && echo "Error: make install" &&  exit $?

rm -f /srv/php
ln -s /srv/php-7.0.0RC3/ /srv/php

strip /srv/php-7.0.0RC3/bin/php
strip /srv/php-7.0.0RC3/sbin/php-fpm 

mkdir -p /srv/php-7.0.0RC3/etc/conf.d
mkdir -p /srv/php-7.0.0RC3/etc/fpm.d
cp /srv/php-7.0.0RC3/etc/pear.conf{,.original}
cp php.ini-* /srv/php-7.0.0RC3/etc/
cp /srv/php-7.0.0RC3/etc/php.ini-production /srv/php-7.0.0RC3/etc/php.ini
cp /srv/php-7.0.0RC3/etc/php.ini-production /srv/php-7.0.0RC3/etc/php-cli.ini
cp /srv/php-7.0.0RC3/etc/php-fpm.conf.default /srv/php-7.0.0RC3/etc/php-fpm.conf
cp /srv/php-7.0.0RC3/etc/php-fpm.d/www.conf.default /srv/php-7.0.0RC3/etc/php-fpm.d/www.conf

yes|cp ./sapi/fpm/php-fpm.service /etc/systemd/system/php-fpm.service 
sed -i 's:${prefix}:/srv/php:g' /etc/systemd/system/php-fpm.service
sed -i 's:${exec_prefix}:/srv/php:g' /etc/systemd/system/php-fpm.service

systemctl enable php-fpm



vim /srv/php-7.0.0RC3/etc/php-fpm.conf <<end > /dev/null 2>&1
:17,17s/;pid/pid/
:24,24s/;error_log/error_log/
:85,85s/;rlimit_files = 1024/rlimit_files = 65536/
:wq
end

vim /srv/php-7.0.0RC3/etc/php-fpm.d/www.conf <<end > /dev/null 2>&1
:107,107s/pm.max_children = 5/pm.max_children = 2048/
:112,112s/pm.start_servers = 2/pm.start_servers = 8/
:117,117s/pm.min_spare_servers = 1/pm.min_spare_servers = 8/
:122,122s/pm.max_spare_servers = 3/pm.max_spare_servers = 16/
:133,133s/;pm.max_requests = 500/pm.max_requests = 1024/
:232,232s/;pm.status_path/pm.status_path/
:244,244s/;ping.path/ping.path/
:249,249s/;ping.response/ping.response/
:330,330s/;request_terminate_timeout = 0/request_terminate_timeout = 30s/
:334,334s/;rlimit_files = 1024/rlimit_files = 40960/
:wq
end

#:15,15s/;//

vim /srv/php-7.0.0RC3/etc/php.ini <<EOF > /dev/null 2>&1
:298,298s$;open_basedir =$open_basedir = /www/:/tmp/:/var/tmp/:/srv/php-7.0.0RC3/lib/php/:/srv/php-7.0.0RC3/bin/$
:303,303s/disable_functions =/disable_functions = ini_set,set_time_limit,set_include_path,passthru,exec,system,chroot,scandir,chgrp,chown,shell_exec,proc_open,proc_get_status,ini_alter,ini_restore,dl,openlog,syslog,readlink,symlink,popepassthru,stream_socket_server,fsocket/
:363,363s/expose_php = On/expose_php = Off/
:393,393s/memory_limit = 128M/memory_limit = 32M/
:773,773s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=1/
:927,927s:;date.timezone =:date.timezone = Asia/Hong_Kong:
:1417,1417s:;session.save_path = "/tmp":session.save_path = "/dev/shm":
:1443,1443s/session.name = PHPSESSID/session.name = JSESSIONID/
:wq
EOF

#s/max_execution_time = 30/max_execution_time = 300/g
#:706,706s!;include_path = ".:/php/includes"!include_path = ".:/srv/php-7.0.0RC3/lib/php:/srv/php-7.0.0RC3/share"!
#:728,728s!; extension_dir = "./"!extension_dir = "./:/srv/php-7.0.0RC3/lib/php/extensions:/srv/php-7.0.0RC3/lib/php/extensions/no-debug-non-zts-20121212"!
#:804,804s/upload_max_filesize = 2M/upload_max_filesize = 3M/

vim /srv/php-7.0.0RC3/etc/php-cli.ini <<EOF > /dev/null 2>&1
:389,389s/memory_limit = 128M/memory_limit = 4G/
:568,568s:;error_log = php_errors.log:error_log = /var/tmp/php_errors.log:
:913,913s:;date.timezone =:date.timezone = Asia/Hong_Kong:
:wq
EOF

cat >> ~/.bashrc <<EOF

alias php='php -c /srv/php/etc/php-cli.ini'
PATH=$PATH:/srv/php/bin:
EOF

cat >> /etc/man.config <<EOF
MANPATH  /srv/php/man/
EOF

cat >> /etc/profile.d/php.sh <<'EOF'
export PATH=/srv/php/bin:$PATH
EOF

source /etc/profile.d/php.sh

systemctl start php-fpm
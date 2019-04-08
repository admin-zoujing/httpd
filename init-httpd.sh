#!/bin/bash
#
#centos7.4编译安装httpd2.4.37
sourceinstall=/usr/local/src/httpd
chmod 777 -R $sourceinstall

#sed -i 's|SELINUX=.*|SELINUX=disabled|' /etc/selinux/config
#sed -i 's|SELINUXTYPE=.*|#SELINUXTYPE=targeted|' /etc/selinux/config
#sed -i 's|SELINUX=.*|SELINUX=disabled|' /etc/sysconfig/selinux 
#sed -i 's|SELINUXTYPE=.*|#SELINUXTYPE=targeted|' /etc/sysconfig/selinux
#setenforce 0 && systemctl stop firewalld && systemctl disable firewalld 
#setenforce 0 && systemctl stop iptables && systemctl disable iptables

rm -rf /var/run/yum.pid 
rm -rf /var/run/yum.pid
#1）解决依赖关系
yum -y install pcre-devel openssl-devel make gcc expat-devel
#cd $sourceinstall/rpm
#rpm -ivh $sourceinstall/rpm/*.rpm --force --nodeps
#2)编译安装apr
cd $sourceinstall
mkdir -pv /usr/local/apr
tar -zxvf apr-1.6.3.tar.gz -C /usr/local/apr
cd /usr/local/apr/apr-1.6.3/
sed -i 's|$RM "$cfgfile"|# $RM "$cfgfile"|' /usr/local/apr/apr-1.6.3/configure
./configure --prefix=/usr/local/apr
make
make install
#3)编译安装apr-util
cd $sourceinstall
mkdir -pv /usr/local/apr-util
tar -zxvf apr-util-1.6.1.tar.gz -C /usr/local/apr-util/
cd /usr/local/apr-util/apr-util-1.6.1/
./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr
make 
make install
#4)编译httpd
cd $sourceinstall
mkdir -pv /usr/local/apache
tar -zxvf httpd-2.4.37.tar.gz -C /usr/local/apache
cd /usr/local/apache/httpd-2.4.37/
./configure --prefix=/usr/local/apache --sysconfdir=/usr/local/apache/conf --enable-so --enable--ssl --enable-cgi --enable-rewrite --with-zlib --with-pcre --with-apr=/usr/local/apr --with-apr-util=/usr/local/apr-util --enable-modeles=most --enable-mpms-shared=all --with-mpm=event --enable-proxy --enable-proxy-http --enable-proxy-ajp --enable-proxy-balancer --enable-lbmethod-heartbeat --enable-heartbeat --enable-slotmem-shm  --enable-slotmem-plain --enable-watchdog
make 
make install

#二进制程序：
echo 'export PATH=/usr/local/apache/bin:$PATH' > /etc/profile.d/httpd.sh 
source /etc/profile.d/httpd.sh
#头文件输出给系统：
ln -sv /usr/local/apache/include /usr/include/httpd
#库文件输出：
#echo '/usr/local/apache/modules' > /etc/ld.so.conf.d/httpd.conf
#让系统重新生成库文件路径缓存
ldconfig
#导出man文件：
echo 'MANDATORY_MANPATH                       /usr/local/apache/man' >> /etc/man_db.conf
source /etc/profile.d/httpd.sh 
sleep 5
source /etc/profile.d/httpd.sh 
#修改配置文件启动
sed -i 's|#ServerName www.example.com:80|ServerName localhost:80|' /usr/local/apache/conf/httpd.conf
#设置开机自启动
cat >> /usr/lib/systemd/system/httpd.service <<EOF
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=forking
ExecStart=/usr/local/apache/bin/httpd -k start
ExecReload=/usr/local/apache/bin/httpd  -k graceful
ExecStop=/usr/local/apache/bin/httpd  -k stop
ExecRestart=/usr/local/apache/bin/httpd  -k restart
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
chown -Rf daemon:daemon /usr/local/apache
systemctl daemon-reload
systemctl enable httpd.service
systemctl restart httpd.service

ps aux |grep httpd
rm -rf $sourceinstall

firewall-cmd --permanent --zone=public --add-port=80/tcp --permanent
firewall-cmd --permanent --query-port=80/tcp
firewall-cmd --reload















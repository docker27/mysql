#!/bin/bash

downloan_url='https://cdn.mysql.com//Downloads/MySQL-5.7/mysql-5.7.27-1.el7.x86_64.rpm-bundle.tar'
downloan_file_name='mysql-5.7.27-1.el7.x86_64.rpm-bundle.tar'
mysql_md5='7e0fe8119abcaa59f5b82f2f5542bbf9';
password='Dev123@wind.COM';

# init
function _init() {
	mkdir -p /opt/mysql/data/ /opt/mysql/log/ /opt/mysql/pid/ /opt/mysql/sock/
#	rm -rf /opt/mysql/data/* /opt/mysql/log/*
	chown -R mysql.mysql /opt/mysql
}

# install
function _install() {
	if [ ! -f /opt/install/${downloan_file_name} ]; then
                echo "mysql tar not exist !!!"
                exit -1
        fi

	md5=`md5sum /opt/install/${downloan_file_name} | awk -F ' ' '{print $1}'`
        if [ $md5 != $mysql_md5 ]; then
                echo "mysql tar md5 incorrect !!!"
                exit -1
        fi

	mysql_is_install=`rpm -qa | grep mysql-community-server-5.7.27-1.el7.x86_64 |wc -l`
	if [ ${mysql_is_install} == 0 ];then
		tar -xvf /opt/install/${downloan_file_name} -C /opt/install/
		yum -y install numactl
		yum -y install libaio
		rpm -ivh /opt/install/mysql-community-common-5.7.27-1.el7.x86_64.rpm 
		rpm -ivh /opt/install/mysql-community-libs-5.7.27-1.el7.x86_64.rpm
		rpm -ivh /opt/install/mysql-community-client-5.7.27-1.el7.x86_64.rpm
		rpm -ivh /opt/install/mysql-community-server-5.7.27-1.el7.x86_64.rpm
		echo 'mysql initialize and chmod mysql data dir'

		mv /etc/my.cnf /etc/my.cnf.bak
		cp /opt/install/my.cnf /etc/my.cnf

		mysqld --initialize
#        	chmod -R 777 /var/lib/mysql/*
		chmod -R 777 /opt/mysql/
		chown -R mysql:mysql /opt/mysql/
	fi
	echo "mysql install success !!!"
}

# config
function _start() {
	# start mysql
	echo "start mysql ..."
#	mysqld --initialize
#	chmod -R 777 /var/lib/mysql/*
#	mv /etc/my.cnf /etc/my.cnf.bak
#	cp /opt/install/my.cnf /etc/my.cnf
	su mysql -c "systemctl start mysqld"
	echo "start mysql finish"	
}

# change pwd
function _changePwd() {
	# 获取数据库密码
	prefix='A temporary password is generated for root@localhost: '
	pwd_default=`grep  "$prefix"  /opt/mysql/log/mysqld.log | awk  -F "$prefix" '{print  $2}'`
	echo $pwd_default
	echo "update password and grant privileges ..."
	mysql -uroot -p"$pwd_default" -e "SET PASSWORD = PASSWORD('Dev123@wind.COM')"  --connect-expired-password;
	mysql -uroot -pDev123@wind.COM -e "use mysql;grant all privileges on *.* to 'root'@'%' identified by 'Dev123@wind.COM';flush privileges;"
	echo "update password and grant privileges finish"
}

# init database
function _initdb() {
	echo "init database tables ..."
	mysql -uroot -pDev123@wind.COM -e "source /opt/install/wind_auth.sql"
	mysql -uroot -pDev123@wind.COM -e "source /opt/install/wind_user.sql"
	mysql -uroot -pDev123@wind.COM -e "source /opt/install/wind_blog.sql"
}

# chkconfig 设置开机启动
function _chkconfig() {
	cd /etc/rc.d/init.d/
	rm -rf /etc/rc.d/init.d/mysql 
	touch /etc/rc.d/init.d/mysql
	chmod +x /etc/rc.d/init.d/mysql
	echo '#!/bin/bash' >> /etc/rc.d/init.d/mysql
	echo '# chkconfig: 12345 95 05' >> /etc/rc.d/init.d/mysql
	echo 'su dev -c "systemctl start mysqld"' >> /etc/rc.d/init.d/mysql
	chkconfig --add mysql
	echo "chkconfig add mysql success"
}

_init
_install
#_start
#_changePwd
#_initdb
_chkconfig

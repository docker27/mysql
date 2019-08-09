docker rm -f mysql_lastest
docker rmi qianchun27/mysql:lastest
docker build -t qianchun27/mysql:lastest -f Dockerfile .
docker run --privileged -t -d -p 3306:3306 --name mysql_lastest qianchun27/mysql:lastest /usr/sbin/init;
docker network connect wind_net mysql_lastest
docker exec -it mysql_lastest /bin/bash

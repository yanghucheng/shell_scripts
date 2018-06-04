#!bin/bash

USER="root"
PASSWORD="123456"
HOST2="192.168.150.140" # 备份主机
DB_NAME="tp5shop"

# Dump数据库到SQL文件
 mysqldump -u"$USER" -p"$PASSWORD" -C --databases "$DB_NAME" |mysql \
 --host=$HOST2 -u"$USER" -p"$PASSWORD" "$DB_NAME"

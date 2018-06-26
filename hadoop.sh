#!/usr/bin/env bash

# Author: yang
# Date: 2018/6/26

export hadoop_log=/opt/hadoop_install.log

# config server environment.
/bin/sed -ri s/SELINUX=enforcing/SELINUX=disabled/g /etc/selinux/config
/bin/setenforce 0
/bin/systemctl stop firewalld && /bin/systemctl disable firewalld &>/dev/null
if [ $? -eq 0 ]; then
	echo "selinux & firewall --- status: OFF" >>$hadoop_log
else
	echo "###selinux & firewall --- status: Need you manual change###"  >>$hadoop_log
fi



# 主机名FQDN
server1=server01.devops.com
server2=server02.devops.com
server3=server03.devops.com
# 主机IP
server1_ip=192.168.150.150
server1_ip=192.168.150.141
server1_ip=192.168.150.140

# s1=`cut -d"." -f1 $server1`
s1=${server1%%.*}
s2=${server2%%.*}
s3=${server3%%.*}

cat > /etc/hosts <<EOF
$server1_ip $server1 $s1
$server2_ip $server1 $s2
$server3_ip $server1 $s3
EOF

# 生成秘钥
ssh-keygen -t dsa -f /root/.ssh/id_dsa  -P "" 

# install jdk 
yum install java-1.8.0-openjdk -y

# hadoop-env.sh
# /usr/lib/jvm/java-1.8.0-openjdk-1.8.0.171-8.b10.el7_5.x86_64/jre/bin/java
/bin/sed -ri s/#  JAVA_HOME=/usr/java/testing hdfs dfs -ls/export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-1.8.0.171-8.b10.el7_5.x86_64/jre/g /opt/hadoop/etc/hadoop/hadoop-env.sh


cat > /opt/hadoop/etc/hadoop/works <<EOF
s2
s3
EOF

# /opt/hadoop/sbin/stop-dfs.sh
sed -i '26i HDFS_DATANODE_USER=root' /opt/hadoop/sbin/stop-dfs.sh
sed -i '27i HDFS_DATANODE_SECURE_USER=hdfs' /opt/hadoop/sbin/stop-dfs.sh
sed -i '28i HDFS_NAMENODE_USER=root' /opt/hadoop/sbin/stop-dfs.sh
sed -i '29i HDFS_SECONDARYNAMENODE_USER=root' /opt/hadoop/sbin/stop-dfs.sh

# /opt/hadoop/sbin/start-dfs.sh
sed -i '37i HDFS_DATANODE_USER=root' /opt/hadoop/sbin/start-dfs.sh
sed -i '38i HDFS_DATANODE_SECURE_USER=hdfs' /opt/hadoop/sbin/start-dfs.sh
sed -i '39i HDFS_NAMENODE_USER=root' /opt/hadoop/sbin/start-dfs.sh
sed -i '40i HDFS_SECONDARYNAMENODE_USER=root' /opt/hadoop/sbin/start-dfs.sh


# /opt/hadoop/sbin/stop-yarn.sh
sed -i '21i YARN_RESOURCEMANAGER_USER=root' /opt/hadoop/sbin/stop-yarn.sh
sed -i '22i HADOOP_SECURE_DN_USER=yarn' /opt/hadoop/sbin/stop-yarn.sh
sed -i '23i YARN_NODEMANAGER_USER=root' /opt/hadoop/sbin/stop-yarn.sh


# /opt/hadoop/sbin/start-yarn.sh
sed -i '21i YARN_RESOURCEMANAGER_USER=root' /opt/hadoop/sbin/start-yarn.sh
sed -i '22i HADOOP_SECURE_DN_USER=yarn' /opt/hadoop/sbin/start-yarn.sh
sed -i '23i YARN_NODEMANAGER_USER=root' /opt/hadoop/sbin/start-yarn.sh

# core-site.xml
mv /opt/hadoop/etc/hadoop/core-site.xml /opt/hadoop/etc/hadoop/core-site.xml.bak
cat > /opt/hadoop/etc/hadoop/core-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
       <!--指定namenode的地址-->

 <property>
   <name>fs.default.name</name>
   <value>hdfs://s1:9007</value>
 </property>
       <!--用来指定使用hadoop时产生文件的存放目录-->
 <property>
   <name>hadoop.tmp.dir</name>
   <value>/opt/hadoop/tmp</value>
 </property>

</configuration>
EOF

# hdfs-site.xml
mv /opt/hadoop/etc/hadoop/hdfs-site.xml /opt/hadoop/etc/hadoop/hdfs-site.xml.bak
cat > /opt/hadoop/etc/hadoop/hdfs-site.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
<!--指定hdfs保存数据的副本数量-->
 <property>
   <name>dfs.replication</name>
   <value>3</value>
 </property>
<!--指定hdfs中namenode的存储位置-->
 <property>
   <name>dfs.namenode.name.dir</name>
   <value>file:/opt/hadoop/dfs/name</value>
 </property>
<!--指定hdfs中datanode的存储位置-->
 <property>
   <name>dfs.datanode.data.dir</name>
   <value>file:/opt/hadoop/dfs/data</value>
 </property>
</configuration>
EOF

# mapred-site.xml
mv /opt/hadoop/etc/hadoop/mapred-site.xml /opt/hadoop/etc/hadoop/mapred-site.xml.bak
cat > /opt/hadoop/etc/hadoop/mapred-site.xml <<EOF
<configuration>
<!--告诉hadoop以后MR(Map/Reduce)运行在YARN上-->
   <property>
       <name>mapreduce.framework.name</name>
       <value>yarn</value>
   </property>

<property>
　　<name>mapreduce.map.memory.mb</name>
　　<value>512</value>
</property>
<property>
　　<name>mapreduce.map.java.opts</name>
　　<value>-Xmx512M</value>
</property>
<property>
　　<name>mapreduce.reduce.memory.mb</name>
　　<value>1024</value>
</property>
<property>
　　<name>mapreduce.reduce.java.opts</name>
　　<value>-Xmx1024M</value>
</property>

<property>
　　<name>yarn.nodemanager.vmem-check-enabled</name>
　　<value>false</value>
</property>

<property>
<name>mapreduce.application.classpath</name>
<value>
/opt/hadoop/etc/hadoop,
/opt/hadoop/share/hadoop/common/*,
/opt/hadoop/share/hadoop/common/lib/*,
/opt/hadoop/share/hadoop/hdfs/*,
/opt/hadoop/share/hadoop/hdfs/lib/*,
/opt/hadoop/share/hadoop/mapreduce/*,
/opt/hadoop/share/hadoop/mapreduce/lib/*,
/opt/hadoop/share/hadoop/yarn/*,
/opt/hadoop/share/hadoop/yarn/lib/*
</value>
</property>
</configuration>
EOF

# yarn-site.xml
mv /opt/hadoop/etc/hadoop/yarn-site.xml /opt/hadoop/etc/hadoop/yarn-site.xml.bak
cat > /opt/hadoop/etc/hadoop/yarn-site.xml <<EOF
<configuration>

<!-- Site specific YARN configuration properties -->

<!-- 参数解释：NodeManager上运行的附属服务。需配置成mapreduce_shuffle，才可运行MapReduce程序-->
 <property>
   <name>yarn.nodemanager.aux-services</name>
   <value>mapreduce_shuffle</value>
 </property>
 <property>
   <name>yarn.nodemanager.aux-services.mapreduce.shuffle.class</name>
   <value>org.apache.hadoop.mapred.ShuffleHandler</value>
 </property>
<!-- 参数解释：ResourceManager 对客户端暴露的地址。客户端（用户）通过该地址向RM提交应用程序，杀死应用程序等。-->
 <property>
   <name>yarn.resourcemanager.address</name>
   <value>s1:8032</value>
 </property>
 <property>
<!-- 参数解释：ResourceManager 对ApplicationMaster暴露的访问地址。ApplicationMaster通过该地址向RM申请资源、释放资源等。-->
   <name>yarn.resourcemanager.scheduler.address</name>
   <value>s1:8030</value>
 </property>
<!-- 参数解释：ResourceManager -> master 对NodeManager -> slave暴露的地址.。NodeManager通过该地址向RM汇报心跳，领取任务等。 -->
 <property>
   <name>yarn.resourcemanager.resource-tracker.address</name>
   <value>s1:8031</value>
 </property>
<!-- 参数解释：ResourceManager 对管理员暴露的访问地址。管理员通过该地址向RM发送管理命令等。 -->
 <property>
   <name>yarn.resourcemanager.admin.address</name>
   <value>s1:8033</value>
 </property>
<!-- 参数解释：ResourceManager对外web ui地址。用户可通过该地址在浏览器中查看集群各类信息。 -->
 <property>
   <name>yarn.resourcemanager.webapp.address</name>
   <value>s1:8088</value>
 </property>
</configuration>
EOF

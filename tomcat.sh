#!/bin/bash
# Install Java
amazon-linux-extras install java-openjdk11 -y

MAJOR_VERSION=11
TOMCAT_VERSION=11.0.0-M22

wget https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz
tar xvf openjdk-17.0.2_linux-x64_bin.tar.gz
sudo mv jdk-17.0.2/ /opt/jdk-17
sudo tee /etc/profile.d/jdk.sh <<EOF
export JAVA_HOME=/opt/jdk-17
export PATH=\$PATH:\$JAVA_HOME/bin
EOF

source /etc/profile.d/jdk.sh


# Construct the download URL
TOMCAT_URL="https://dlcdn.apache.org/tomcat/tomcat-$MAJOR_VERSION/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz"

echo "Fetching Tomcat version $TOMCAT_VERSION from $TOMCAT_URL"


# Download and extract Tomcat
wget $TOMCAT_URL
tar -zxvf apache-tomcat-$TOMCAT_VERSION.tar.gz

read -p "Enter password for Tomcat user: " password
echo

# Configure Tomcat users
sed -i '56  a\<role rolename="manager-gui"/>' apache-tomcat-$TOMCAT_VERSION/conf/tomcat-users.xml
sed -i '57  a\<role rolename="manager-script"/>' apache-tomcat-$TOMCAT_VERSION/conf/tomcat-users.xml
sed -i '58  a\<user username="apachetomcat" password="'"$password"'" roles="manager-gui,manager-script"/>' apache-tomcat-$TOMCAT_VERSION/conf/tomcat-users.xml
sed -i '59  a\</tomcat-users>' apache-tomcat-$TOMCAT_VERSION/conf/tomcat-users.xml
sed -i '56d' apache-tomcat-$TOMCAT_VERSION/conf/tomcat-users.xml
sed -i '21d' apache-tomcat-$TOMCAT_VERSION/webapps/manager/META-INF/context.xml
sed -i '22d' apache-tomcat-$TOMCAT_VERSION/webapps/manager/META-INF/context.xml

# Start Tomcat
sh apache-tomcat-$TOMCAT_VERSION/bin/startup.sh

 
touch tomcatcreds.txt
echo "username: apachetomcat" > tomcatcreds.txt
echo "password: $password" >> tomcatcreds.txt


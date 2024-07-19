#!/bin/bash

# Load Tomcat versions from environment file
#!/bin/bash
export MAJOR_VERSION=$(grep 'MAJOR_VERSION' tomcat_versions.env | cut -d '=' -f2)
export TOMCAT_VERSION=$(grep 'TOMCAT_VERSION' tomcat_versions.env | cut -d '=' -f2)


# Construct the download URL
TOMCAT_URL="https://dlcdn.apache.org/tomcat/tomcat-${MAJOR_VERSION}/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"

echo "Fetching Tomcat version ${TOMCAT_VERSION} from ${TOMCAT_URL}"

# Install Java
sudo amazon-linux-extras install java-openjdk11 -y

# Download and extract Tomcat
wget $TOMCAT_URL
tar -zxvf apache-tomcat-${TOMCAT_VERSION}.tar.gz

# Configure Tomcat users
sed -i '56  a\<role rolename="manager-gui"/>' apache-tomcat-${TOMCAT_VERSION}/conf/tomcat-users.xml
sed -i '57  a\<role rolename="manager-script"/>' apache-tomcat-${TOMCAT_VERSION}/conf/tomcat-users.xml
sed -i '58  a\<user username="tomcat" password="raham123" roles="manager-gui,manager-script"/>' apache-tomcat-${TOMCAT_VERSION}/conf/tomcat-users.xml
sed -i '59  a\</tomcat-users>' apache-tomcat-${TOMCAT_VERSION}/conf/tomcat-users.xml
sed -i '56d' apache-tomcat-${TOMCAT_VERSION}/conf/tomcat-users.xml
sed -i '21d' apache-tomcat-${TOMCAT_VERSION}/webapps/manager/META-INF/context.xml
sed -i '22d' apache-tomcat-${TOMCAT_VERSION}/webapps/manager/META-INF/context.xml

# Start Tomcat
sh apache-tomcat-${TOMCAT_VERSION}/bin/startup.sh

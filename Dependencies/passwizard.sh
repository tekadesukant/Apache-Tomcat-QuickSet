#!/bin/bash

# Prompt the user to enter a new password
echo "Enter new Tomcat manager password (minimum 6 characters): "
read CUSTOM_TOMCAT_PASSWD

# Update the password in tomcat-users.xml
sudo sed -i '58  c <user username="apachetomcat" password="'"$CUSTOM_TOMCAT_PASSWD"'" roles="manager-gui,manager-script"/>' /opt/tomcat/conf/tomcat-users.xml

# Update the password in tomcatcreds.txt
sudo sed -i '2 c password="'"$CUSTOM_TOMCAT_PASSWD"'"' /opt/tomcatcreds.txt

echo "Password successfully updated."

# Optionally restart Tomcat to apply the new password
# sudo tomcat -restart

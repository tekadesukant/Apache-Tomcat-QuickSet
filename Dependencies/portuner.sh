#!/bin/bash
# Prompt the user to enter a new port number
echo "Enter new port number (1024-65535): "
read CUSTOM_TOMCAT_PORT

# Update the port number in server.xml
echo "Updating port in server.xml..."
sudo sed -i ' /<Connector port/  c \ \ \ \ <Connector port="'$CUSTOM_TOMCAT_PORT'" protocol="HTTP/1.1" '  /opt/tomcat/conf/server.xml

# Update the portnumber in tomcatcreds.txt
echo "Updating port number in tomcatcreds.txt..."
sudo sed -i '4 c portnumber='$CUSTOM_TOMCAT_PORT' ' /opt/tomcreds.txt

echo "Port number successfully updated to "'$CUSTOM_TOMCAT_PORT'". "
echo "Restart Tomcat using (comm: tomcat --restart) to apply the changes"


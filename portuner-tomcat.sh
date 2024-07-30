#!/bin/bash
# TESTED SUCCESFULLY FOR UBUNTU INSTANCE
# Prompt the user to enter a new port number
echo "Enter new port number (1024-65535): "
read CUSTOM_TOMCAT_PORT

# Update the port number in server.xml
sudo sed -i 's/port="8080"/port="'"$CUSTOM_TOMCAT_PORT"'"/' /opt/tomcat/conf/server.xml

# Update the portnumber in tomcatcreds.txt
sudo sed -i '4 c portnumber="'"$CUSTOM_TOMCAT_PORT"'"' /opt/tomcatcreds.txt

echo "Port number successfully updated to "'"$CUSTOM_TOMCAT_PORT"'". "

# Optionally, check Tomcat service status
if systemctl is-active --quiet tomcat; then
    echo "Tomcat is currently running. Please restart Tomcat (comm: tomcat -restart) to apply changes."
else
    echo "Tomcat is not running. You can start Tomcat (comm: tomcat -start) to apply the new port number."
fi

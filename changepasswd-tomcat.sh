#!/bin/bash

# Prompt the user to enter a new password
echo "Enter new Tomcat manager password (minimum 6 characters): "
read CUSTOM_TOMCAT_PASSWD

# Validate password (minimum 8 characters)
if [ ${#CUSTOM_TOMCAT_PASSWD} -lt 6 ]; then
    echo "Password must be at least 6 characters long."
    exit 1
fi

# Update the password in tomcat-users.xml
sudo sed -i 's/password="[^"]*"/password="'"$CUSTOM_TOMCAT_PASSWD"'"/' /opt/tomcat/conf/tomcat-users.xml

# Update the password in tomcatcreds.txt
sudo sed -i 's/password="[^"]*"/password="'"$CUSTOM_TOMCAT_PASSWD"'"/' /opt/tomcatcreds.txt

# Check if the updates were successful
if [ $? -eq 0 ]; then
    echo "Password successfully updated."

    # Optionally restart Tomcat to apply the new password
    sudo tomcat -restart

else
    echo "Failed to update password."
    exit 1
fi

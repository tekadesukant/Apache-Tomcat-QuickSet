#!/bin/bash

# Prompt the user to enter a new port number
echo "Enter new port number (1024-65535): "
read CUSTOM_TOMCAT_PORT

# Validate the port number
if [[ ! "$CUSTOM_TOMCAT_PORT" =~ ^[0-9]+$ ]] || [ "$CUSTOM_TOMCAT_PORT" -lt 1024 ] || [ "$CUSTOM_TOMCAT_PORT" -gt 65535 ]; then
    echo "Invalid port number. Please enter a number between 1024 and 65535."
    exit 1
fi

# Update the port number in server.xml
sudo sed -i 's/port="8080"/port="'$CUSTOM_TOMCAT_PORT'"/' /opt/tomcat/conf/server.xml

# Check if the operation was successful
if [ $? -eq 0 ]; then
    echo "Port number successfully updated to $CUSTOM_TOMCAT_PORT."

    # Optionally, check Tomcat service status
      if systemctl is-active --quiet tomcat; then
          echo "Tomcat is currently running. Please restart Tomcat to apply changes."
      else
          echo "Tomcat is not running. You can start Tomcat to apply the new port number."
      fi
else
    echo "Failed to update port number."
    exit 1
fi

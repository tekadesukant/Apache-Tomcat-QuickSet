#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Stopping Tomcat service..."
sudo /opt/tomcat/bin/shutdown.sh || echo "Tomcat may not be running."

echo "Waiting for Tomcat to shut down..."
sleep 10

echo "Removing Tomcat directory..."
sudo rm -rf /opt/tomcat/

echo "Removing JDK installation..."
sudo rm -rf /opt/jdk-17/

echo "Removing Tomcat symlink or executable from sbin..."
sudo rm -f /usr/local/sbin/tomcat

echo "Removing configuration and helper scripts..."
sudo rm -f /opt/tomcreds.txt
sudo rm -f /opt/portuner.sh
sudo rm -f /opt/passwd.sh
sudo rm -f /opt/fetechport.sh

echo "✅ Tomcat and associated files removed successfully from the machine."

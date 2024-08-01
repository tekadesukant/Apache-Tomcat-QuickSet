#!/bin/bash
sudo /opt/tomcat/bin/shutdown.sh
sleep 10
sudo rm -r /opt/tomcat/
sudo rm -r /opt/jdk-17/
sudo rm -r /usr/local/sbin/tomcat
sudo rm -f /opt/tomcreds.txt
sudo rm -f /opt/portuner.sh
sudo rm -f /opt/passwd.sh
echo "Tomcat removed successfully from the machine"

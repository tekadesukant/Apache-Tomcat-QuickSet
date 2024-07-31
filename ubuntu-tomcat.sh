#!/bin/bash

# Note: This script has been tested on an Ubuntu server 22.04 LTS (HVM).

# Fetched latest version 
TOMCAT_VERSION=11.0.0-M22
# Previous Versions : 9.0.91, 10.1.26

# Extracting major version from fetched version
MAJOR_VERSION=$(echo "$TOMCAT_VERSION" | cut -d'.' -f1)

# Define log file
LOG_FILE="/var/log/tomcat_installation.log"

# Function to log messages with timestamps
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Start logging
log "Starting Tomcat installation script..."

set -e  # Exit immediately if a command exits with a non-zero status

# Update package lists and install Java 17
log "Updating package lists..."
sudo apt update
sudo apt-get update
log "Installing Java development kit..."
sudo add-apt-repository ppa:openjdk-r/ppa
# Install Java 11
sudo apt install openjdk-11-jdk -y
# Install Java 17
sudo apt install openjdk-17-jdk -y
log "Java installed."

# Construct the download URL for Tomcat
TOMCAT_URL="https://dlcdn.apache.org/tomcat/tomcat-$MAJOR_VERSION/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz"

log "Fetching Tomcat version $TOMCAT_VERSION from $TOMCAT_URL"

# Download and extract Tomcat
log "Downloading Tomcat..."
wget $TOMCAT_URL
tar -zxvf apache-tomcat-$TOMCAT_VERSION.tar.gz
mv apache-tomcat-$TOMCAT_VERSION tomcat

# Move Tomcat to /opt and set permissions
log "Moving Tomcat to /opt and setting permissions..."
sudo mv tomcat /opt/
sudo chown -R $USER:$USER /opt/tomcat

# Configure Tomcat users
password=tomcat123
TOMCAT_USER_CONFIG="/opt/tomcat/conf/tomcat-users.xml"
log "Configuring Tomcat users..."
sudo sed -i '56  a\<role rolename="manager-gui"/>' $TOMCAT_USER_CONFIG
sudo sed -i '57  a\<role rolename="manager-script"/>' $TOMCAT_USER_CONFIG
sudo sed -i '58  a\<user username="apachetomcat" password="'"$password"'" roles="manager-gui,manager-script"/>' $TOMCAT_USER_CONFIG
sudo sed -i '59  a\</tomcat-users>' $TOMCAT_USER_CONFIG
sudo sed -i '56d' $TOMCAT_USER_CONFIG
sudo sed -i '21d' /opt/tomcat/webapps/manager/META-INF/context.xml
sudo sed -i '22d' /opt/tomcat/webapps/manager/META-INF/context.xml

# Start Tomcat
log "Starting Tomcat..."
/opt/tomcat/bin/startup.sh

# Creating and Integrating tomcat commands script
sudo tee /opt/portuner.sh <<'EOF'
#!/bin/bash
# Note : This Script Tested Succesfully on UBUNTU INSTANCE
# Prompt the user to enter a new port number
echo "Enter new port number (1024-65535): "
read CUSTOM_TOMCAT_PORT

# Update the port number in server.xml
sudo sed -i 's/port="8080"/port="'"$CUSTOM_TOMCAT_PORT"'"/' /opt/tomcat/conf/server.xml

# Update the portnumber in tomcatcreds.txt
sudo sed -i '4 c portnumber="'"$CUSTOM_TOMCAT_PORT"'"' /opt/tomcatcreds.txt

echo "Port number successfully updated to "'"$CUSTOM_TOMCAT_PORT"'". "
#echo "Please restart Tomcat (comm: tomcat --restart) to apply changes."

#restart Tomcat to apply the new port number
echo "Restarting tomcat to apply the new port..."
sudo tomcat --restart
echo "Tomcat restarted succesfully"
EOF

sudo chmod +x /opt/portuner.sh

sudo tee /opt/passwd.sh <<'EOF'
#!/bin/bash

# Prompt the user to enter a new password
echo "Enter new Tomcat manager password (minimum 6 characters): "
read CUSTOM_TOMCAT_PASSWD

# Update the password in tomcat-users.xml
sudo sed -i '58  c <user username="apachetomcat" password="'"$CUSTOM_TOMCAT_PASSWD"'" roles="manager-gui,manager-script"/>' /opt/tomcat/conf/tomcat-users.xml

# Update the password in tomcatcreds.txt
sudo sed -i '2 c password="'"$CUSTOM_TOMCAT_PASSWD"'"' /opt/tomcatcreds.txt

echo "Password successfully updated."
#echo "Please restart Tomcat (comm: tomcat --restart) to apply changes."

#restart Tomcat to apply the new password
echo "Restarting tomcat to apply the new password..."
sudo tomcat --restart
echo "Tomcat restarted succesfully"
EOF

sudo chmod +x /opt/passwd.sh

sudo tee /opt/remove.sh <<'EOF'
#!/bin/bash
sudo /opt/tomcat/bin/shutdown.sh
sleep 10
sudo rm -r /opt/tomcat/
sudo rm -r /usr/local/sbin/tomcat
sudo rm -f /opt/tomcreds.txt
sudo rm -f /opt/portuner.sh
sudo rm -f /opt/passwd.sh
echo "Tomcat removed successfully"
EOF

sudo chmod +x /opt/remove.sh

# Create the tomcat script
sudo tee /usr/local/sbin/tomcat << 'EOF'
#!/bin/bash

case "$1" in
    --up)
        echo "Starting Tomcat..."
        sudo -u root /opt/tomcat/bin/startup.sh
        ;;
    --down)
        echo "Stopping Tomcat..."
        sudo -u root /opt/tomcat/bin/shutdown.sh
        ;;
    --restart)
        echo "Restarting Tomcat..."
        echo "Stopping Tomcat..."
        sudo -u root /opt/tomcat/bin/shutdown.sh
        sleep 5  # Wait for Tomcat to stop completely
        echo "Starting Tomcat..."
        sudo -u root /opt/tomcat/bin/startup.sh
        ;;
    --delete)
        echo "Removing Tomcat..."
        sudo -u root /opt/remove.sh
        ;;
    --port-change)
        sudo -u root /opt/portuner.sh
        ;;
    --passwd-change)
        sudo -u root /opt/passwd.sh
        ;;
    *)
        echo "Usage: tomcat {--up|--down|--restart|--delete|--port-change|--passwd-change}"
        ;;
esac
EOF

sudo chmod +x /usr/local/sbin/tomcat

# Add an alias to the .bashrc file
echo "alias tomcat='/usr/local/sbin/tomcat'" >> ~/.bashrc

# Reload the .bashrc file
log "Reloading .bashrc..."
. ~/.bashrc

# Save Tomcat credentials
log "Saving Tomcat credentials..."
sudo tee /opt/tomcreds.txt > /dev/null <<EOF
username:apachetomcat
password:tomcat123
tomcat path:/opt/tomcat
port number:8080

<-Integrated Tomcat Commands For You->
- RUN TOMCAT: sudo tomcat --up
- STOP TOMCAT: sudo tomcat --down
- RESTART TOMCAT: sudo tomcat --restart
- REMOVE TOMCAT: sudo tomcat --delete
- CHANGE PASSWORD TOMCAT: sudo tomcat --passwd-change
- CHANGE PORT NUMBER TOMCAT: sudo tomcat --port-change

Follow me - linkedIn/in/tekade-sukant | Github.com/tekadesukant
EOF

# Clean up
log "Cleaning up..."
rm -f apache-tomcat-$TOMCAT_VERSION.tar.gz

# Tomcat installation and configuration final touch up 
log "Tomcat Assest "
cat /opt/tomcreds.txt
log "Tomcat installation and configuration complete."
exec bash

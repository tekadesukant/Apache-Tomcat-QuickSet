#!/bin/bash
# Define log file
LOG_FILE="/var/log/tomcat_installation.log"

MAJOR_VERSION=11     
TOMCAT_VERSION=11.0.0-M22    
#Previous Version : 9.0.91, 10.1.26

# Function to log messages with timestamps
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# Start logging
log "Starting Tomcat installation script..."

set -e  # Exit immediately if a command exits with a non-zero status

# Check if Tomcat is already installed
if [ -d "/opt/tomcat" ]; then
    log "Tomcat version $TOMCAT_VERSION is already installed."
    exit 0
fi

# Update package lists and install Java 17
log "Updating package lists..."
sudo apt update
log "Installing Java 17..."
sudo apt install openjdk-17-jdk -y

# Verify Java installation
java -version

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

password=tomcat123

# Configure Tomcat users
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

# Save Tomcat credentials
log "Saving Tomcat credentials..."
echo "username: apachetomcat" > tomcatcreds.txt
echo "password: $password" >> tomcatcreds.txt
echo "tomcat path: /opt/tomcat" >> tomcatcreds.txt
echo "port number: publicip:8080" >> tomcatcreds.txt
echo "COMM TO RUN TOMCAT:sudo tomcat -up" >> tomcatcreds.txt 
echo "COMM TO STOP TOMCAT:sudo tomcat -down" >> tomcatcreds.txt 

# Clean up
log "Cleaning up..."
rm -f apache-tomcat-$TOMCAT_VERSION.tar.gz

# Create the tomcat script
sudo tee /usr/local/sbin/tomcat << 'EOF'
#!/bin/bash

case "$1" in
    -up)
        sudo -u root /opt/tomcat/bin/startup.sh
        ;;
    -down)
        sudo -u root /opt/tomcat/bin/shutdown.sh
        ;;
    *)
        echo "Usage: tomcat {-up|-down}"
        ;;
esac
EOF

# Make the tomcat script executable
sudo chmod +x /usr/local/sbin/tomcat

# Add an alias to the .bashrc file
echo "alias tomcat='/usr/local/sbin/tomcat'" >> ~/.bashrc
log "Tomcat installation and configuration complete."
# Reload the .bashrc file
exec bash
sleep 5


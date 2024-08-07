#!/bin/bash

# Note: This script has been tested on an Amazon Linux 2 AMI (HVM).

# Latest version successfully fetched 
TOMCAT_VERSION=11.0.0-M24
# Previous Versions : 9.0.93, 10.1.28

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

# Download and install Java 11 and java 17
log "Installing Java Development Kit..."
# Install Java 11
amazon-linux-extras install java-openjdk11 -y
# Install Java 17
sudo wget https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz
sudo tar xvf openjdk-17.0.2_linux-x64_bin.tar.gz
sudo mv jdk-17.0.2 /opt/jdk-17
sudo tee /etc/profile.d/jdk.sh > /dev/null <<EOF
export JAVA_HOME=/opt/jdk-17
export PATH=\$PATH:\$JAVA_HOME/bin
EOF
source /etc/profile.d/jdk.sh
log "Installed Java Development Kit Successfully." 

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
sudo chown -R $(whoami):$(whoami) /opt/tomcat

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

# Save Tomcat credentials
log "Saving Tomcat credentials..."
sudo tee /opt/tomcreds.txt > /dev/null <<EOF
username:apachetomcat
password:tomcat123
tomcat path:/opt/tomcat
portnumber:8080

< Integrated Tomcat Commands For You >
- Start Tomcat: tomcat --up 
- Stop Tomcat: tomcat --down
- Restart Tomcat: tomcat --restart
- Remove Tomcat: tomcat --delete
- Print Current PortNumber: tomcat --port
- Change Tomcat PortNumber: tomcat --port-change
- Change Tomcat Password: tomcat --passwd-change

Follow me - linkedIn/in/tekade-sukant | Github.com/tekadesukant

EOF

# Creating and Integrating tomcat commands script 
sudo tee /opt/portuner.sh <<'EOF'
#!/bin/bash
# Store the provided port number 
echo "Changing Tomcat port to $1..."

# Update the port number in server.xml
sudo sed -i ' /<Connector port/  c \ \ \ \ <Connector port="'$1'" protocol="HTTP/1.1" '  /opt/tomcat/conf/server.xml

# Update the portnumber in tomcatcreds.txt
sed -i '4 i portnumber:'$1' ' /opt/tomcreds.txt
sed -i '5d' /opt/tomcreds.txt

echo "Port number successfully updated to $1. "
echo "Restart tomcat (comm: tomcat --restart) to apply chnages"
EOF

sudo chmod +x /opt/portuner.sh

sudo tee /opt/passwd.sh > /dev/null <<'EOF'
#!/bin/bash
# Store the provided port number 

echo "Changing Tomcat password..."
# Update the password in tomcat-users.xml
sudo sed -i '58  c <user username="apachetomcat" password="'$1'" roles="manager-gui,manager-script"/>' /opt/tomcat/conf/tomcat-users.xml

# Update the password in tomcatcreds.txt
sudo sed -i '2 c password='$1' ' /opt/tomcreds.txt

echo "Password successfully updated."
EOF

sudo chmod +x /opt/passwd.sh

sudo tee /opt/remove.sh <<'EOF'
#!/bin/bash
sudo /opt/tomcat/bin/shutdown.sh
sleep 10
sudo rm -r /opt/tomcat/
sudo rm -r /opt/jdk-17/
sudo rm -r /usr/local/sbin/tomcat
sudo rm -f /opt/tomcreds.txt
sudo rm -f /opt/portuner.sh
sudo rm -f /opt/passwd.sh
echo "Tomcat removed successfully"
EOF

sudo chmod +x /opt/remove.sh

# Create the tomcat script
sudo tee /usr/local/sbin/tomcat > /dev/null <<'EOF'
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
        sudo rm -r /opt/remove.sh
        ;;
    --port)
        sudo -u root /opt/fetchport.sh
        ;;  
    --port-change)
        sudo -u root /opt/portuner.sh "$2" 
        ;;
    --passwd-change)
        sudo -u root /opt/passwd.sh "$2"
        ;;
    --help)
        echo "Usage: tomcat {--up (start) | --down (stop) |--restart (stop -> start)}"
        echo "Usage: tomcat {--delete (remove tomcat completely) | --help (list all commands)}"
        echo "Usage: tomcat {--port (print current port) | --port-change <new_port> (change port number)}"
        echo "Usage: tomcat {--passwd (print current password) | --passwd-change <new_passwd> (change password)}"
        ;;
    *)
        echo "Usage: tomcat {--up|--down|--restart|--delete|--port|--port-change <new_port>|--passwd-change <new_password>}"
        ;;
esac
EOF

sudo chmod +x /usr/local/sbin/tomcat

# Add an alias to the .bashrc file
echo "alias tomcat='/usr/local/sbin/tomcat'" >> ~/.bashrc

source ~/.bashrc

# Clean up
log "Cleaning up..."
rm -f apache-tomcat-$TOMCAT_VERSION.tar.gz
rm -f openjdk-17.0.2_linux-x64_bin.tar.gz

# Tomcat installation and configuration final touch up 
log "Tomcat Assest"
cat /opt/tomcreds.txt
log "Tomcat installation and configuration complete."
exec bash 

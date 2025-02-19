#!/bin/bash

# Note: This script has been tested on an Ubuntu 22.04/24.04, RHEL 8/9, Debian 12 and Amazon Linux 2/2023. Testing on Debian 10/11, CentOS Stream 8/9 instance is currently in progress.

# Latest version successfully fetched 
TOMCAT_VERSION=11.0.4
# Previous Versions : 9.0.100, 10.1.36

# Extracting major version from fetched version
MAJOR_VERSION=$(echo "$TOMCAT_VERSION" | cut -d'.' -f1)

# Define log file path
LOG_FILE="/var/log/tomcat_installation.log"

# Function to log messages with timestamps
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Start logging
log "Starting Tomcat installation script..."

set -e  # Exit immediately if a command exits with a non-zero status

# Detect the operating system
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
elif [ -f /etc/redhat-release ]; then
    OS="centos"
else
    log "Unsupported OS"
    exit 1
fi

sudo yum install wget -y || sudo apt-get update -y; sudo apt install wget -y

# Fetch supported Java version for the current Tomcat version
RELEASE_NOTES_URL="https://archive.apache.org/dist/tomcat/tomcat-$MAJOR_VERSION/v$TOMCAT_VERSION/RELEASE-NOTES"
SUPPORTED_JAVA=$(wget -qO- "$RELEASE_NOTES_URL" | \
    grep -iE "Tomcat.*is designed to run on Java" | \
    sed -E 's/.*run on Java ([0-9]+).*/\1/' | head -1)

if [ -z "$SUPPORTED_JAVA" ]; then
     log "Supported Java version for Tomcat $TOMCAT_VERSION: Java $SUPPORTED_JAVA"
fi

# System-specific JDK installation
if [ "$OS" = "amzn" ]; then
    log "Amazon Linux detected. Installing Java Development Kit..."
    if [ "$SUPPORTED_JAVA" -ne "8" ]; then
        sudo yum install java-$SUPPORTED_JAVA-amazon-corretto -y || true   
        sudo yum install java-$SUPPORTED_JAVA-amazon-corretto-devel -y || true
    elif [ "$SUPPORTED_JAVA" = "8" ]; then
        sudo amazon-linux-extras enable corretto8 || sudo dnf update -y
        sudo yum install java-1.8.0-amazon-corretto-devel -y
    else
        log "Unsupported Java version $SUPPORTED_JAVA for Amazon Linux."
        exit 1
    fi
    log "Installed Java $SUPPORTED_JAVA successfully."
elif [ "$OS" = "rhel" ] || [ "$OS" = "centos" ]; then
    log "RHEL/CentOS detected. Installing Java Development Kit..."
    if [ "$SUPPORTED_JAVA" = "8" ]; then
        sudo yum install java-1.8.0-openjdk-devel -y
    elif [ "$SUPPORTED_JAVA" -ne "8" ]; then
        sudo yum install java-$SUPPORTED_JAVA-openjdk-devel -y
    else
        log "Unsupported Java version $SUPPORTED_JAVA for RHEL or CentOS."
        exit 1
    fi
    log "Installed Java $SUPPORTED_JAVA successfully."
elif [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
    log "Ubuntu/Debian detected. Updating package lists..."
    sudo apt update -y
    sudo apt-get upgrade -y
    log "Installing Java Development Kit..."
    sudo add-apt-repository ppa:openjdk-r/ppa -y || true
    sudo apt install openjdk-$SUPPORTED_JAVA-jdk -y

    log "Installed Java $SUPPORTED_JAVA successfully."
else
    log "Unsupported OS detected. Cannot proceed with the installation."
    exit 1
fi

# Construct the download URL for Tomcat
TOMCAT_URL="https://dlcdn.apache.org/tomcat/tomcat-$MAJOR_VERSION/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz"

log "Fetching Tomcat version $TOMCAT_VERSION from $TOMCAT_URL"

# Common tomcat installation steps
log "Downloading Tomcat..."
wget $TOMCAT_URL
tar -zxvf apache-tomcat-$TOMCAT_VERSION.tar.gz
mv apache-tomcat-$TOMCAT_VERSION tomcat

# Move Tomcat to /opt 
log "Moving Tomcat to /opt and setting permissions..."
sudo mv tomcat /opt/

# set permissions
log "Setting permissions..."
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
echo "Restarting tomcat..."
tomcat --restart
echo "Tomcat restart succesfully."
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
echo "Restarting tomcat..."
tomcat --restart
echo "Tomcat restart succesfully."
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

sudo tee /opt/fetchport.sh <<'EOF'
#!/bin/bash
echo "Current-$(sed -n '/portnumber/p' /opt/tomcreds.txt)"
#sed -n '4p' /opt/tomcreds.txt
EOF

sudo chmod +x /opt/fetchport.sh

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
        echo "Commands:"
        echo "--up: Start Tomcat"
        echo "--down: Stop Tomcat"
        echo "--restart: Restart Tomcat"
        echo "--delete: Remove Tomcat"
        echo "--port: Show current port"
        echo "--port-change <port>: Change port"
        echo "--passwd-change <password>: Change password"
        ;;
    *)
        echo "Invalid command. Use --help for options."
        ;;
esac
EOF

sudo chmod +x /usr/local/sbin/tomcat

# Add an alias to the .bashrc file
echo "alias tomcat='/usr/local/sbin/tomcat'" >> ~/.bashrc

# Clean up
log "Cleaning up..."
rm -f apache-tomcat-$TOMCAT_VERSION.tar.gz

log "Tomcat installation and configuration complete."
exec bash 

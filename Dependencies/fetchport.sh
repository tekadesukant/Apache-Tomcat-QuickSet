#!/bin/bash

# Extract and display the current Tomcat port from tomcatcreds.txt
echo "Current-$(sed -n '/portnumber/p' /opt/tomcreds.txt)"

# Alternative direct line extraction (uncomment if needed)
# sed -n '4p' /opt/tomcreds.txt

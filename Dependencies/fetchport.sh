#!/bin/bash
echo "Current-$(sed -n '/portnumber/p' /opt/tomcreds.txt)"
#sed -n '4p' /opt/tomcreds.txt

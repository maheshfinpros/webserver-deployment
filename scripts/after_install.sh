#!/bin/bash

# Determine the instance ID of the current EC2 instance
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Check if the current instance is web server 1
if [[ $INSTANCE_ID == "i-09759cd2f95e9f5f9" ]]; then
    # Copy index1.html to the web server directory
    cp /path/to/index1.html /var/www/html/index.html
fi

# Check if the current instance is web server 2
if [[ $INSTANCE_ID == "i-06b7c8a20f24b5af5" ]]; then
    # Copy index1.html to the web server directory
    cp /path/to/index1.html /var/www/html/index.html
fi

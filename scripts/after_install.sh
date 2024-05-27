#!/bin/bash
# after_install.sh

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

if [[ $INSTANCE_ID == "i-09759cd2f95e9f5f9" ]]; then
  echo "Instance 1 detected. Moving index1.html to index.html"
  cp /var/www/html/index1.html /var/www/html/index.html
elif [[ $INSTANCE_ID == "i-06b7c8a20f24b5af5" ]]; then
  echo "Instance 2 detected. Moving index2.html to index.html"
  cp /var/www/html/index2.html /var/www/html/index.html
else
  echo "Instance ID does not match known instances."
fi

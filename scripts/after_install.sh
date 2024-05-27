#!/bin/bash
# after_install.sh

INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

# Set permissions and ownership
sudo chmod 644 /var/www/html/index1.html /var/www/html/index2.html
sudo chown www-data:www-data /var/www/html/index1.html /var/www/html/index2.html
sudo chmod 755 /var/www/html
sudo chown www-data:www-data /var/www/html

# Remove the old index.html file if it exists
sudo rm -rf /var/www/html/index.html

if [[ $INSTANCE_ID == "i-09759cd2f95e9f5f9" ]]; then
  echo "Instance 1 detected. Moving index1.html to index.html"
  mv /var/www/html/index1.html /var/www/html/index.html
elif [[ $INSTANCE_ID == "i-06b7c8a20f24b5af5" ]]; then
  echo "Instance 2 detected. Moving index2.html to index.html"
  mv /var/www/html/index2.html /var/www/html/index.html
else
  echo "Instance ID does not match known instances."
fi

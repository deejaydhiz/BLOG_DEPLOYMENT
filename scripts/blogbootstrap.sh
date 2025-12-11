#!/bin/bash

# echo "Installing Dependencies"
# echo "======================================================================"
# sudo dnf upgrade -y
# sudo dnf install mariadb105-server httpd wget php-mysqlnd php-fpm php-mysqli php-json php php-devel -y
# sudo dnf install -y nfs-utils git cronie
# echo "======================================================================"

# echo "Starting Services"
# sudo systemctl start httpd mariadb crond
# sudo systemctl enable httpd mariadb crond
# echo "======================================================================"

# echo "Setting Permissions"
# sudo usermod -a -G apache ec2-user   
# sudo chown -R ec2-user:apache /var/www     
# sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;   
# find /var/www -type f -exec sudo chmod 0664 {} \;    

#EFS CREATION AND MOUNTING
EFS=$(aws ssm get-parameter --name "blogdb-EFS" --query "Parameter.Value" --output text)
MOUNT_POINT=/var/www/html
mkdir -p ${MOUNT_POINT}
chown ec2-user:ec2-user ${MOUNT_POINT}
echo ${EFS}:/ ${MOUNT_POINT} nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev 0 0 >> /etc/fstab
mount -a -t nfs4
chmod -R 755 /var/www/html

# DB_NAME=$(aws ssm get-parameter --name "arn:aws:ssm:us-east-1:651974166650:parameter/database/name" --query "Parameter.Value" --output text --region us-east-1)
# DB_USER=$(aws ssm get-parameter --name "arn:aws:ssm:us-east-1:651974166650:parameter/database/user" --query "Parameter.Value" --output text --region us-east-1)
# DB_PASS=$(aws ssm get-parameter --name "arn:aws:ssm:us-east-1:651974166650:parameter/database/password" --query "Parameter.Value" --output text --region us-east-1)
DB_HOST=$(aws ssm get-parameter --name "blogdb-host" --query "Parameter.Value" --output text)
DB_NAME=$(aws ssm get-parameter --name "blogdb-name" --query "Parameter.Value" --output text)
DB_USER=$(aws ssm get-parameter --name "blogdb-user" --query "Parameter.Value" --output text)
DB_PASS=$(aws ssm get-parameter --name "blogdb-pass" --query "Parameter.Value" --output text)
BLOG_DNS=$(aws ssm get-parameter --name "blog-DNS" --query "Parameter.Value" --output text)
ADMIN=$(aws ssm get-parameter --name "blog_admin_pw" --query "Parameter.Value" --output text)

if [ ! -f "/var/www/html/wp-config.php" ]   # Check if WordPress is not already configured
then
    echo "Downloading WordPress from GitHub repo"
    git clone https://github.com/deejaydhiz/Dejis-Blog.git
    cp -rp Dejis-Blog/* /var/www/html/
    cd /var/www/html
    cp wp-config-sample.php wp-config.php

    sed -i "s/database_name_here/${DB_NAME}/" /var/www/html/wp-config.php
    sed -i "s/username_here/${DB_USER}/" /var/www/html/wp-config.php
    sed -i "s/password_here/${DB_PASS}/" /var/www/html/wp-config.php
    sed -i "s/localhost/${DB_HOST}/" /var/www/html/wp-config.php

    until mysql -u admin -p"${ADMIN}" -h ${DB_HOST} -e "SELECT 1" >/dev/null 2>&1
    do
      echo "Waiting for database to be ready..."
      sleep 10
    done

    # Update IP to point to load balancer
    mysql -u "${DB_USER}" -p"${DB_PASS}" -h "${DB_HOST}" -D "${DB_NAME}" << EOF
        UPDATE wp_options SET option_value = "${BLOG_DNS}" WHERE option_value LIKE 'http:%';
EOF
else
    echo "WordPress is already configured on this server."

    mysql -u "${DB_USER}" -p"${DB_PASS}" -h "${DB_HOST}" -D "${DB_NAME}" << EOF
        UPDATE wp_options SET option_value = "${BLOG_DNS}" WHERE option_id = siteurl;
        UPDATE wp_options SET option_value = "${BLOG_DNS}" WHERE option_id = home;
EOF
fi

# update wp-config.php every minute by comparing the updated db password from SSM Parameter Store
echo "#!/bin/bash" > /var/www/html/wp-config_check.sh
echo "echo 'Checking for updates to wp-config.php parameters'" >> /var/www/html/wp-config_check.sh
echo "NEW_PWD=\$(aws ssm get-parameter --name \"blogdb-pass\" --query \"Parameter.Value\" --output text)" >> /var/www/html/wp-config_check.sh
echo "" >> /var/www/html/wp-config_check.sh
# DB PASSWORD check
echo "OLD_PWD=\$(grep 'DB_PASSWORD' /var/www/html/wp-config.php | awk -F\"'\" '{print \$4}')" >> /var/www/html/wp-config_check.sh
echo "if [ \"\${OLD_PWD}\" == \"\${NEW_PWD}\" ]; then" >> /var/www/html/wp-config_check.sh
echo "    echo 'wp-config.php already has updated parameters for the host'" >> /var/www/html/wp-config_check.sh
echo "else" >> /var/www/html/wp-config_check.sh
echo "    echo 'Updating wp-config.php with latest parameters'" >> /var/www/html/wp-config_check.sh
echo "    sudo sed -i s/\${OLD_PWD}/\${NEW_PWD}/ /var/www/html/wp-config.php" >> /var/www/html/wp-config_check.sh
echo "fi" >> /var/www/html/wp-config_check.sh

chmod +x /var/www/html/wp-config_check.sh   

TS=$(date +%Y%m%d)

# write out current crontab
crontab -l > mycron
# echo new cron into cron file
echo "* * * * * /var/www/html/wp-config_check.sh > /home/ec2-user/wpcheck_${TS}.log 2>&1" >> mycron
# Install new cron file
crontab mycron
rm mycron

echo "Installing Dependencies"
echo "======================================================================"
sudo dnf upgrade -y
sudo dnf install mariadb105-server httpd wget php-mysqlnd php-fpm php-mysqli php-json php php-devel -y
sudo dnf install -y nfs-utils git cronie

echo "Starting Services"
sudo systemctl start httpd mariadb crond
sudo systemctl enable httpd mariadb crond
echo "======================================================================"

echo "Setting Permissions"
sudo usermod -a -G apache ec2-user   
sudo chown -R ec2-user:apache /var/www     
sudo chmod 2775 /var/www && find /var/www -type d -exec sudo chmod 2775 {} \;   
find /var/www -type f -exec sudo chmod 0664 {} \;    
echo "======================================================================"
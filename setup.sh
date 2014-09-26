#! /bin/bash

# Set timezone
echo "Europe/Berlin" | sudo tee /etc/timezone
sudo dpkg-reconfigure --frontend noninteractive tzdata

# console setup
echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8, ru_RU.UTF-8 UTF-8" | debconf-set-selections
echo "locales locales/default_environment_locale select ru_RU.UTF-8" | debconf-set-selections
sed -i 's/^# ru_RU.UTF-8 UTF-8/ru_RU.UTF-8 UTF-8/' /etc/locale.gen
dpkg-reconfigure --frontend=noninteractive locales
export LANG=ru_RU.UTF-8

sudo apt-get -y update
sudo apt-get -y upgrade

sudo locale-gen ru_RU.UTF-8

#install mysql server
if [ ! -f /var/log/mysql.setup ];
then
echo mysql-server mysql-server/root_password password root | sudo debconf-set-selections
echo mysql-server mysql-server/root_password_again password root | sudo debconf-set-selections
sudo apt-get install -y mysql-server mysql-client
fi

#install soft
if [ ! -f /var/log/soft.setup ];
then
sudo apt-get install -y git-core curl wget mc atop htop
sudo touch /var/log/soft.install
fi

#install apache2
if [ ! -f /var/log/soft.setup ];
then
sudo apt-get install -y apache2
sudo a2enmod rewrite
sudo touch /var/log/apache2.install
fi

#install php
if [ ! -f /var/log/php.install ];
then
sudo apt-get install -y php5 libapache2-mod-php5 php5-cli php5-mysql php5-curl php5-gd php5-mcrypt php-pear php5-xdebug
sudo php5enmod mcrypt
sudo touch /var/log/php.install
fi

#install phpmyadmin
if [ ! -f /var/log/phpmyadmin.install ];
then
    echo 'phpmyadmin phpmyadmin/dbconfig-install boolean false' | debconf-set-selections
	echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections

	echo 'phpmyadmin phpmyadmin/app-password-confirm password root' | debconf-set-selections
	echo 'phpmyadmin phpmyadmin/mysql/admin-pass password root' | debconf-set-selections
	echo 'phpmyadmin phpmyadmin/password-confirm password root' | debconf-set-selections
	echo 'phpmyadmin phpmyadmin/setup-password password root' | debconf-set-selections
	echo 'phpmyadmin phpmyadmin/database-type select mysql' | debconf-set-selections
	echo 'phpmyadmin phpmyadmin/mysql/app-pass password root' | debconf-set-selections

	echo 'dbconfig-common dbconfig-common/mysql/app-pass password root' | debconf-set-selections
	echo 'dbconfig-common dbconfig-common/password-confirm password root' | debconf-set-selections
	echo 'dbconfig-common dbconfig-common/app-password-confirm password root' | debconf-set-selections
	echo 'dbconfig-common dbconfig-common/app-password-confirm password root' | debconf-set-selections
	echo 'dbconfig-common dbconfig-common/password-confirm password root' | debconf-set-selections
sudo apt-get install -y phpmyadmin
sudo touch /var/log/phpmyadmin.install
fi

#Configure mysql server
if [ ! -f /var/log/mysql.setup ];
then
    # Allow root access from any host
    echo "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION" | mysql -u root --password=root
    echo "GRANT PROXY ON ''@'' TO 'root'@'%' WITH GRANT OPTION" | mysql -u root --password=root
    sudo touch /var/log/mysql.setup
fi


#Install Composer
if [ ! -f /var/log/composer.install ];
then
    sudo curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
    sudo touch /var/log/composer.install
fi

#CONFIGURATION

# Configure PHP
if [ ! -f /var/log/php.setup ];
then
    # Set timezone
    sudo sed -i "s/;date.timezone =/date.timezone = Europe\/Berlin/" /etc/php5/apache2/php.ini
    sudo sed -i "s/;date.timezone =/date.timezone = Europe\/Berlin/" /etc/php5/cli/php.ini

    # Enable short tag
    sudo sed -i "s/short_open_tag = On/short_open_tag = Off/" /etc/php5/apache2/php.ini
    sudo sed -i "s/short_open_tag = On/short_open_tag = Off/" /etc/php5/cli/php.ini

    # Display Errors
    sudo sed -i '/display_errors = Off/c display_errors = On' /etc/php5/apache2/php.ini
    sudo sed -i '/display_errors = Off/c display_errors = On' /etc/php5/cli/php.ini
    sudo sed -i '/error_reporting = E_ALL & ~E_DEPRECATED/c error_reporting = E_ALL | E_STRICT' /etc/php5/apache2/php.ini
    sudo sed -i '/error_reporting = E_ALL & ~E_DEPRECATED/c error_reporting = E_ALL | E_STRICT' /etc/php5/cli/php.ini
    sudo sed -i '/html_errors = Off/c html_errors = On' /etc/php5/apache2/php.ini
    sudo sed -i '/html_errors = Off/c html_errors = On' /etc/php5/apache2/php.ini

    sudo sed -i '/log_errors = Off/c log_errors = On' /etc/php5/apache2/php.ini
    sudo sed -i '/log_errors = Off/c log_errors = On' /etc/php5/cli/php.ini

    sudo sed -i '/upload_max_filesize = 2M/c upload_max_filesize = 64M' /etc/php5/apache2/php.ini
    sudo sed -i '/upload_max_filesize = 2M/c upload_max_filesize = 64M' /etc/php5/cli/php.ini

    sudo sed -i '/post_max_size = 8M/c post_max_size = 64M' /etc/php5/apache2/php.ini
    sudo sed -i '/post_max_size = 8M/c post_max_size = 64M' /etc/php5/cli/php.ini

    sudo sed -i '/;error_log = php_errors.log/c error_log = /var/log/php_errors.log' /etc/php5/apache2/php.ini
    sudo sed -i '/;error_log = php_errors.log/c error_log = /var/log/php_errors.log' /etc/php5/apache2/php.ini

    sudo touch /var/log/php.setup
fi

# Configure Apache2
if [ ! -f /var/log/apache2.setup ];
then
    sudo sed -i 's/AllowOverride None/AllowOverride all/' /etc/apache2/apache2.conf
    sudo sed -i 's/export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=vagrant/' /etc/apache2/envvars
    sudo sed -i 's/export APACHE_RUN_GROUP=www-data/export APACHE_RUN_GROUP=vagrant/' /etc/apache2/envvars
    # If you want to install a different path to the web directory. For example:
    #sudo sed -i 's/DocumentRoot \/var\/www/DocumentRoot \/mnt\/var\/www\/html/g' /etc/apache2/sites-available/default
    #sudo sed -i 's/<Directory \/var\/www\/>/<Directory \/mnt\/var\/www\/html\/>/' /etc/apache2/sites-available/default
    sudo sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www\/public/g' /etc/apache2/sites-available/000-default.conf
    sudo sed -i 's/DocumentRoot \/var\/www\/html/DocumentRoot \/var\/www\/public/g' /etc/apache2/sites-available/default-ssl.conf
    #sudo sed -i 's/<Directory \/var\/www\/>/<Directory \/var\/www\/public\/>/' /etc/apache2/apache2.conf
    #sudo sed -i 's/<Directory \/var\/www\/html/>/<Directory \/var\/www\/public\/>/' /etc/apache2/sites-available/default
    sudo touch /var/log/apache2.setup
fi

#install laravel
if [ ! -f /var/log/laravel.install ];
then
    sudo rm -rf /var/www/*
    sudo composer create-project laravel/laravel --prefer-dist /var/www
    sudo touch /var/log/laravel.install
fi

#setup laravel
if [ ! -f /var/log/laravel.setup ];
then
    sudo rm -rf /var/www/*
    sudo sed -i 's/\'database\'  => \'forge\'/\'database\'  => \'database\'/' /var/www/public/app/config/database.php
    sudo sed -i 's/\'username\'  => \'forge\'/\'username\'  => \'root\'/' /var/www/public/app/config/database.php
    sudo sed -i 's/\'password\'  => \'\'/\'password\'  => \'root\'/' /var/www/public/app/config/database.php
    sudo touch /var/log/laravel.setup
fi

#install ngrok
if [ ! -f /var/log/ngrok.install ];
then
    #sudo apt-get install ngrok-client
    sudo touch /var/log/ngrok.install
fi

#restart apache2 mysql
sudo service apache2 restart
sudo service mysql restart





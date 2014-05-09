#!/bin/bash
#
# Script d'installation MediasTorrent / Nginx
#Liens du projet MediasTorrent " http://www.wareziens.net/forum/topic-21408-mediastorrent-un-front-end-multi-user-multi-seedbox-multi-medias-page-1.html "

clear
 
    if [ $(id -u) -ne 0 ]
    then
       echo
       echo "This script must be run as root." 1>&2
       echo
       exit 1
    fi
 
    # demander nom et mot de passe
    read -p "Adding user now, please type your user name: " user
    read -s -p "Enter password: " pwd
    echo
 
    # ajout utilisateur
    useradd -m  -s /bin/bash "$user"
 
    # creation du mot de passe pour cet utilisateur
    echo "${user}:${pwd}" | chpasswd
    
    #email
    echo "le script a besoin de votre Ã©mail en cas de perte de mot de passe exemple"
    echo ""
    read -p "votre email : " mail
    
    #mysql root
    echo "entrez un mot de passe complex pour mysql root" 
    echo""
    read -p "root mysql password : " pwdr

 # gestionnaire de paquet
if [ "`dpkg --status aptitude | grep Status:`" == "Status: install ok installed" ]
then
        packetg="aptitude"
else
        packetg="apt-get"
fi


ip=$(ip addr | grep eth0 | grep inet | awk '{print $2}' | cut -d/ -f1)

##Log de l'instalation
exec 2>/home/$user/log

$packetg update
$packetg safe-upgrade -y
$packetg install -y  git-core memcached autoconf build-essential comerr-dev libcloog-ppl-dev libcppunit-dev 
$packetg install -y  libcurl3 libcurl4-openssl-dev libncurses5-dev ncurses-base ncurses-term libterm-readline-gnu-perl
$packetg install -y  dtach libsigc++-2.0-dev libssl-dev libtool libxml2-dev subversion curl
$packetg install -y  apache2 libapache2-mod-php5 php5-mysqlnd php5-json php5-imagick php5-memcached php5-curl

#install mysql-server
echo "mysql-server-5.1 mysql-server/root_password password $pwdr" | debconf-set-selections
echo "mysql-server-5.1 mysql-server/root_password_again password $pwdr" | debconf-set-selections
$packetg install -y install mysql-server


###########################################################
##     Installation XMLRPC Libtorrent Rtorrent           ##
###########################################################

svn checkout http://svn.code.sf.net/p/xmlrpc-c/code/stable xmlrpc-c
cd xmlrpc-c
./configure --disable-cplusplus
make
make install
cd ..
rm -rv xmlrpc-c


#clone rtorrent et libtorrent
wget --no-check-certificate http://libtorrent.rakshasa.no/downloads/libtorrent-0.13.2.tar.gz
tar -xf libtorrent-0.13.2.tar.gz

wget --no-check-certificate http://libtorrent.rakshasa.no/downloads/rtorrent-0.9.2.tar.gz
tar -xzf rtorrent-0.9.2.tar.gz

# libtorrent compilation
cd libtorrent-0.13.2
./autogen.sh
./configure
make
make install

# rtorrent compilation
cd ../rtorrent-0.9.2
./autogen.sh
./configure --with-xmlrpc-c
make
make install

ldconfig
###########################################################
##              Fin Instalation                          ##
###########################################################

##Installation de Mediastorrent

a2enmod rewrite
service apache2 restart
cd /home/$user
git clone -b Dev  https://github.com/salorium/Mediastorrent.git
ln -s /home/$user/Mediastorrent /var/www/Mediastorrent

##Configuration d'apache2
mv /etc/apache2/sites-available/default  /etc/apache2/sites-available/default.bak
cat <<'EOF' >    /etc/apache2/sites-available/default
<VirtualHost *:80>
        ServerAdmin webmaster@localhost

        DocumentRoot /var/www
        <Directory />
                Options FollowSymLinks
                AllowOverride all
        </Directory>
        <Directory /var/www/>
                Options Indexes FollowSymLinks MultiViews
                AllowOverride all
                Order allow,deny
                allow from all
        </Directory>

        ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
        <Directory "/usr/lib/cgi-bin">
                AllowOverride None
                Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
                Order allow,deny
                Allow from all
        </Directory>

        ErrorLog ${APACHE_LOG_DIR}/error.log

        # Possible values include: debug, info, notice, warn, error, crit,
        # alert, emerg.
        LogLevel warn

        CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

EOF

#crÃ©ation de dossier
mkdir -p rtorrent/data 
mkdir -p rtorrent/session

##permissions
chown -R $user:$user /home/$user
chown root:$user /home/$user
chmod 755 /home/$user
chmod -R a+w /home/$user/Mediastorrent/config/Conf.php
chmod -R a+w /home/$user/Mediastorrent/log
chmod -R a+w /home/$user/Mediastorrent/cache


#copie de fichier 
cp /home/$user/Mediastorrent/script/rtorrent /etc/init.d
chmod a+x /etc/init.d/rtorrent
cp /home/$user/Mediastorrent/script/.rtorrent.rc /home/$user
chown gaaara:gaaara /home/gaaara/.rtorrent.rc

sed -i.bak "s#PHPDIR=/home/salorium/Mediastorrent/script#PHPDIR=/home/$user/Mediastorrent/script#g;" /etc/init.d/rtorrent
sed -i.bak "s/$debuglocalfile = false;/$debuglocalfile = true;/g;" /home/darky/Mediastorrent/config/Conf.php

php /home/$user/Mediastorrent/script/preparebbd.php localhost root $pwdr
php /home/$user/Mediastorrent/script/script/inituser.php $user ${pwd} $mail  $ip/Mediastorrent seedadmin 5001

service apache2 restart
/etc/init.d/rtorrent start $user 5001

#!/bin/bash
#
# Script d'installation MediasTorrent / Nginx
#Liens du projet MediasTorrent " http://www.wareziens.net/forum/topic-21408-mediastorrent-un-front-end-multi-user-multi-seedbox-multi-medias-page-1.html "
#le support du script c'est ici http://forum.mediastorrent.com/index.php/Thread/9-Script-support/ 
##############Merci a salorium pour sons aide#################
clear

echo "le script n'est pas pret faite n a la question pour quitter "
echo ""
echo "Dépendence obligatoir avoir installer et configurer lvm"
echo ""
echo "http://forum.mediastorrent.com/index.php/Board/2-Informations/"
echo ""
read -p "avez vous installer et configurer lvm (Y/N)?"
[ "$(echo $REPLY | tr [:upper:] [:lower:])" == "y" ] || exit


    # Fonction d'affichage de l'erreur du mdp
mdperreur() {
        echo "Mot de passe invalide"
        echo "Votre mot de passe doit contenir impérativement une majuscule, une miniscule, un chiffre et avoir une longueur minimum de 8 caractère"
}

    if [ $(id -u) -ne 0 ]
    then
       echo
       echo "This script must be run as root." 1>&2
       echo
       exit 1
    fi
 
    # demander nom et mot de passe
    echo "Au moins 8 caractères avec une lettre majuscule, un chiffre / un caractère spécial."
    echo ""
    read -p "Entrer votre nom d'utilisateur: " user
    OK=1
    while [ $OK -eq 1 ]; do
     read -s -p "Entrer votre mot de passe : " pwd
     echo
     echo "Tesing password strength..."
     echo
     echo $pwd
     if echo "$pwd" | egrep '(^.{8,}$)' > /dev/null #Si le mdp fais une longueur de 8 minimum
      then
       if echo "$pwd" | egrep '(.*[[:digit:]])' > /dev/null #Si le mdp contient au moins un chiffre
        then
         if echo "$pwd" | egrep '(.*[[:lower:]])' > /dev/null #Si le mdp contient une minuscule
          then
           if echo "$pwd" | egrep '(.*[[:upper:]])' > /dev/null #Si le mdp contient une majuscule
            then
             OK=0
             echo "Mdp bon"
            else
             mdperreur #Appelle de la fonction mdperreur
           fi
          else
           mdperreur
         fi
        else
         mdperreur
       fi
      else
       mdperreur
     fi
    done

    echo
 
    # ajout utilisateur
    useradd -m  -s /bin/bash "$user"
 
    # creation du mot de passe pour cet utilisateur
    echo "${user}:${pwd}" | chpasswd
    
    #email
    echo "le script a besoin de votre email en cas de perte de mot de passe exemple"
    echo ""
    read -p "votre email : " mail
    
    #root mysql password generator 
 pwdr=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

 # gestionnaire de paquet
if [ "`dpkg --status aptitude | grep Status:`" == "Status: install ok installed" ]
then
        packetg="aptitude"
else
        packetg="apt-get"
fi

# dossier variable 


if [ -z $homedir ]
then
        homedir="/home/$user"
fi

if [ -z $script ]
then
        script="/home/$user/Mediastorrent/script"
fi

if [ -z $Mediastorrent ]
then
        Mediastorrent="/home/$user/Mediastorrent"
fi

if [ -z $initd ]
then
        initd="/etc/init.d"
fi

if [ -z $rtorrentall ]
then
        rtorrentall="/home/$user/Mediastorrent/blob/Dev/script"
fi


ip=$(ip addr | grep eth0 | grep inet | awk '{print $2}' | cut -d/ -f1)

##Log de l'instalation
exec 2> $homedir/log

$packetg update
$packetg safe-upgrade -y
$packetg install -y  git-core memcached autoconf build-essential comerr-dev libcloog-ppl-dev libcppunit-dev 
$packetg install -y  libcurl3 libcurl4-openssl-dev libncurses5-dev ncurses-base ncurses-term libterm-readline-gnu-perl
$packetg install -y  dtach libsigc++-2.0-dev libssl-dev libtool libxml2-dev subversion curl libssh2-php
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
cd $homedir
git clone -b Dev  https://github.com/salorium/Mediastorrent.git
ln -s $Mediastorrent /var/www/Mediastorrent

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
chown -R $user:$user $homedir
chmod 755  $homedir
chmod -R a+w  $Mediastorrent/config/Conf.php
chmod -R a+w  $Mediastorrent/log
chmod -R a+w  $Mediastorrent/cache


#copie de fichier 
cp $rtorrentall/rtorrentall $initd
chmod +x $initd/rtorrentall
update-rc.d rtorrentall defaults
cp  $script/rtorrent /etc/init.d
chmod a+x  $initd/rtorrent
cp $script/.rtorrent.rc  $homedir
chown $user:$user $homedir/.rtorrent.rc

sed -i.bak "s#PHPDIR=/home/salorium/Mediastorrent/script#PHPDIR=/home/$user/Mediastorrent/script#g;" /etc/init.d/rtorrent
sed -i.bak "s/$debuglocalfile = false;/$debuglocalfile = true;/g;" /home/$user/Mediastorrent/config/Conf.php

php  $script/preparebbd.php localhost root $pwdr
sleep 3
php  $script/inituser.php $user $pwd $mail  $ip/Mediastorrent seedadmin 5001

service apache2 restart

echo "/etc/init.d/rtorrent \$1"$login >> /etc/init.d/rtorrentall
clear

# Demarrage de rtorrent
/etc/init.d/rtorrent start $user 5001
echo "--"
echo " =========== FIN DE L'INSTALLATION ! On dirait que tout a fonctionne ! ==="
echo "Username :$user"
echo "Password :${pwd}"
echo "Mysql password :$pwdr"
echo "Votre email :$mail"
echo "-------------------------------"
echo "-------------------------------"
echo "Maintenant, rendez-vous sur Mediastorrent"
echo "http://$ip/Mediastorrent/"

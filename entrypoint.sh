#!/bin/sh

# Create configuration file for STunnel
# Defaults to Google's G Suite LDAP parameters

cat << EOF > /etc/stunnel/stunnel.conf
foreground = yes

setuid = stunnel
setgid = stunnel

socket = l:TCP_NODELAY=1
socket = r:TCP_NODELAY=1

[${SERVICE:-ldap}]
client = ${CLIENT:-yes}
accept = ${ACCEPT:-1636}
connect = ${CONNECT:-ldap.google.com:636}
cert = /data/stunnel.crt
key = /data/stunnel.key
EOF

# Expects keys to be attached
# Creates directory if they aren't


if ! [ -d /data ]
then
    mkdir /data
    chmod 777 /data
fi

cd /data

# Extracts contents from .zip file if provided

if [ -f /data/*.zip ]
then
    unzip /data/*.zip
fi


# Expects certificate in the /data directory
# Generates new crt/key if they aren't there

if ! [ -f /data/*.crt ] || ! [ -f /data/*.key ]
then
    openssl req -x509 -nodes -newkey rsa:2048 -days 3650 -subj '/CN=stunnel' \
                -keyout stunnel.key -out stunnel.crt
    chmod 600 stunnel.pem
else
    mv -f /data/*.crt /data/stunnel.crt
    mv -f /data/*.key /data/stunnel.key
fi


# Pushes default config from /etc/stunnel/stunnel.conf
# Unless it's specified when the container is ran (as a parameter)


sh -c stunnel /etc/stunnel/stunnel.conf &
sleep 2
ldapsearch -H ldap://localhost:1636 -D ${LDAP_USER:-'user'} -w ${LDAP_PASS:-'pass'} -b ${LDAP_BASESEARCH:-'dc=ldaptest,dc=com'} -s sub -a always -z 1000 $@

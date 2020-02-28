#!/bin/sh

# Create configuration file for STunnel
# Defaults to Google's G Suite LDAP parameters

cd /etc/stunnel

cat << EOF > stunnel.conf
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

# Expects certificate in the /data directory
# Generates new crt/key if they aren't there

if ! [ -f /data/stunnel.crt ]
then
    openssl req -x509 -nodes -newkey rsa:2048 -days 3650 -subj '/CN=stunnel' \
                -keyout stunnel.key -out stunnel.crt
    chmod 600 stunnel.pem
fi


# Pushes default config from /etc/stunnel/stunnel.conf
# Unless it's specified when the container is ran (as a parameter)
# e.g.: docker run \
#       -dit -v /dir:/data \
#       -p 1636:1636 --link ldap \
#       zalgonoise/gstunnel:1.0 /data/stunnel.conf



    sh -c stunnel /etc/stunnel/stunnel.conf &
    sleep 2
    #if [ $# -eq 0 ]
    #then
    #    ldapsearch -H ldap://localhost:1636 -D ${LDAP_USER:-'user'} -w ${LDAP_PASS:-'pass'} -b ${LDAP_BASESEARCH:-'dc=ldaptest,dc=com'} -s sub -a always -z 1000
    #else
        ldapsearch -H ldap://localhost:1636 -D ${LDAP_USER:-'user'} -w ${LDAP_PASS:-'pass'} -b ${LDAP_BASESEARCH:-'dc=ldaptest,dc=com'} -s sub -a always -z 1000 $@
    #fi

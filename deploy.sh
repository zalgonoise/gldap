#!/bin/sh

# Prepare cert and keys
if ! [ -f keys/*.key ]
then
    echo "Please copy your .crt/.key combo into the 'keys' folder, and run the script again."
    exit 1
else
    if ! [ -f keys/stunnel.key  ]
    then
        mv keys/*.key keys/stunnel.key
    fi
    if ! [ -f keys/stunnel.crt ]
    then
        mv keys/*.crt keys/stunnel.crt
    fi
fi

# Check for Docker

if ! [ `command -v docker` ]
then
    echo "Please install docker first."
    exit 1
fi

# Check for running containers

ldap_container_count=$(docker ps | grep -c -i ldap)
stunnel_container_count=$(docker ps | grep -c -i stunnel)

if ! [ $ldap_container_count -eq 0 ]
then
    ldap_container_id=$(docker ps | grep -i 'ldap' | awk '{print $1}')
    docker stop $ldap_container_id

    ldap_dangling=$(docker ps -a | grep -c $ldap_container_id)
    if ! [ $ldap_dangling -eq 0 ]
    then
        docker rm $ldap_container_id
    fi
fi


if ! [ $stunnel_container_count -eq 0 ]
then
    stunnel_container_id=$(docker ps | grep -i 'stunnel' | awk '{print $1}')
    docker stop $stunnel_container_id

    stunnel_dangling=$(docker ps -a | grep -c $stunnel_container_id)
    if ! [ $stunnel_dangling -eq 0 ]
    then
        docker rm $stunnel_container_id
    fi
fi




# Launch LDAP
rt_ldap_id=$( \
docker run \
-d --rm \
--name ldap \
-p 636:636 \
osixia/openldap:1.3.0) \
&& export rt_ldap_id

# Launch and link STunnel
rt_stunnel_id=$( \
docker run \
-dit --rm \
--name stunnel \
--link ldap \
-p 1636:1636 \
-v `pwd`/keys:/data \
zalgonoise/gstunnel:1.0) \
&& export rt_stunnel_id

# Prepare environment

stunnel_ip=$(docker inspect stunnel | grep -i '"ipaddress": ' | head -1 | awk '{print $2}' | tr ',' ' ')
LDAP_HOST=${stunnel_ip//\"/}
export LDAP_HOST=${LDAP_HOST// /}

if [ -z ${LDAP_USER} ]
then
    echo "Enter LDAP User: "
    read LDAP_USER
    if [ -z LDAP_USER ]
    then
        echo "Defaulting to: user"
        export LDAP_USER
    else
        export LDAP_USER
    fi
fi

if [ -z ${LDAP_PASS} ]
then
    export LDAP_PASS_OPT=-W
else
    export LDAP_PASS_OPT="-w ${LDAP_PASS}"
fi

if [ -z ${LDAP_BASESEARCH} ]
then
    echo "No Base Search found. Enter your domain: "
    read LDAP_BASESEARCH
    if [ -z LDAP_BASESEARCH ]
    then
        echo "defaulting to: dc=ldaptest,dc=com"
        export LDAP_BASESEARCH="dc=ldaptest,dc=com"
    else
        export LDAP_BASESEARCH
    fi
fi

if [ "$#" -gt 0 ]
then
    export LDAP_FILTER=$@
else
    export LDAP_FILTER="(objectClass=*)"
fi

# Dumping environment

echo -e "\nDumping Environment:\n"
env|grep LDAP
echo


# Check container runtime ~ 3 second healthcheck delay

sleep 3

ldap_rt_chk=$(docker ps | grep ${rt_ldap_id:0:8} | grep -c Up)
stunnel_rt_chk=$(docker ps | grep ${rt_stunnel_id:0:8} | grep -c Up)

if [ $ldap_rt_chk -eq 0 ]
then
    echo "Something went wrong with the OpenLDAP container. Please check and try again or report this issue."
    exit 1
fi

if [ $stunnel_rt_chk -eq 0 ]
then
    echo "Something went wrong with the STunnel container. Please check and try again or report this issue."
    exit 1
fi



# LDAP Search

echo "Querying:
ldapsearch -H ldap://${LDAP_HOST}:1636 -D ${LDAP_USER} ${LDAP_PASS_OPT} -b ${LDAP_BASESEARCH} ${LDAP_FILTER}

"

docker exec \
-ti ldap \
ldapsearch \
-H ldap://${LDAP_HOST}:1636 \
-D ${LDAP_USER} \
${LDAP_PASS_OPT} \
-b ${LDAP_BASESEARCH} \
${LDAP_FILTER}

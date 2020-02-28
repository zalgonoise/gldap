# gldap





### Google LDAP Deployment and Querying tools

A simple and light Docker image for querying G Suite domains via Secure LDAP.

Google G Suite LDAP queries can be performed with OpenLDAP and STunnel, which are the sole tenantes of this image.

The purpose is to be able to query and test your LDAP queries, in an easy and quick way - without ever leaving crums behind.


### Environment Definition

Deploying in an ephemeral approach is the preferred way, as STunnel takes little to no time launching. It is encouraged to keep the clean-up-after-yourself flag [`--rm`].

The private `.crt/.key` combination that you've downloaded should be moved into the `keys` folder and renamed `stunnel` as such:

```bash
/path/to/repo/keys/stunnel.crt
/path/to/repo/keys/stunnel.key
```

Which you can do after you've downloaded them. Unzip the archive into the `keys` folder, `cd` into it and run the commands:

```bash
cp *.crt stunnel.crt
cp *.key stunnel.key
```

The `keys` folder is the folder attached to the container holding the certificates. It should be linked to the `/data` folder in the container.

Finally define the following environment variables when starting the container:

```
LDAP_USER=username
LDAP_PASS=password
LDAP_BASESEARCH=dc=ldaptest,dc=eu
```

### Container Deployment

Either export, source or replace the variables from the command below to perform a query:

```bash
docker run --rm -ti \
    --name gldap \
    -v `pwd`/keys:/data \
    -e LDAP_USER=$LDAP_USER \
    -e LDAP_PASS=$LDAP_PASS \
    -e LDAP_BASESEARCH=$LDAP_BASESEARCH \
    zalgonoise/gldap:latest \
    $LDAP_FILTER
```

You will be returned an output of the STunnel service, followed by the result of your LDAP query.


~ ZalgoNoise ~ 2020 ~ 

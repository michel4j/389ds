# 389ds
Dockerized 389ds with TLS


389 Directory Server(389ds) is an enterprise-class Open Source LDAP server for Linux.

This image provides  a dockerized 389ds with TLS authentication support, data 
persistence  support through volumes and easy management of server certificates.


# Usage
The best way to use the image is with docker-compose by adapting the sample 
'docker-compose.yml' file.

    ldap:
      image: 389ds:latest
      hostname: ldap.example.com
      volumes:
        - ./data:/var/lib/dirsrv:Z
        - ./config:/etc/dirsrv:Z
        - ./logs:/var/log/dirsrv:Z
        - ./certs:/certs:Z
      environment:
        DIR_SUFFIX: dc=example,dc=lan
        DIR_ADMIN_USERNAME: "myadmin"
        DIR_MANAGER_PASSWORD: "Admin123"
        DIR_ADMIN_UID: "15000"
        DIR_USERS_HOME: "/users"
      ports:
        - 389:389
        - 636:636
      restart: always

Then run the service with

    docker-compose up

# Environment Variables
You can customize how the 389ds instance will be created through environment
variables.
<dl>
<dt>DIR_HOSTNAME</dt>
<dd>The hostname to use for the directory server by default this will be the fully qualified container hostname provided
in docker-compose.yml or the hostname provided through the --hostname from `docker run`. A fully qualified hostname is required

<dt>DIR_ADMIN_USERNAME</dt>
<dd>The username of the default admin account to be created in LDAP, will be `bladmin` if not specified</dd>
<dt>DIR_ADMIN_PASSWORD</dt>
<dd>The password for the default admin account password, will be same as DIR_MANAGER_PASSWORD or `Admin123` if neither is specified</dd>
<dt>DIR_ADMIN_UID</dt>
<dd>The admin account uid</dd>
<dt>DIR_MANAGER_PASSWORD</dt>
<dd>The password for the Directory Manager, will be same as DIR_ADMIN_PASSWORD or `Admin123` if neither is specified</dd>
<dt>DIR_SUFFIX</dt>
<dd>The base DN of the directory instance (eg. "dc=example,dc=com"} default will be "dc=example,dc=com" if not specified</dd>
<dt>DIR_USERS_HOME</dt>
<dd>The top level directory where user accounts should be created. Default is "/home"</dd>
<dt>DIR_USERS_SHELL</dt>
<dd>The shell for user accounts.Default is "/bin/bash"</dd>
</dl>
# Volumes
To preserve configuration and data between restarts and recreating the container, the following volumes should be mounted
<dl>
<dt>/etc/dirsrv</dt>
<dd>location where instance configuration data is stored. Must be empty initially</dd>
<dt>/var/lib/dirsrv</dt>
<dd>database storage location. Must be empty initially</dd>
<dt>/var/log/dirsrv</dt>
<dd>location where logs will be stored. Must be empty initially</dd>
<dt>/certs</dt>
<dd>Certificate import directory. The image expects to find the following files in this directory
<dl>
<dt>server.key</dt>
    <dd>X509 Private Key file in PEM format (mandatory)</dd>
    <dt>server.crt</dt>
    <dd>X509 Certificate file in PEM format (mandatory)</dd>
    <dt>ca.pem</dt>
    <dd>Public key of the Certificate Authority who signed the server certificate in PEM format (optional). For TLS, Make 
    sure ca.pem is recognized by the client</dd>
    </dl>
    To update certificate and key files just replace those with new ones and restart the container.  
</dd>
</dl>
    
# Testing

    ldapsearch -x -ZZ -h localhost -D "cn=Directory Manager" -b "dc=example,dc=com" -W

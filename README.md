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
DIR_HOSTNAME:  The hostname to use for the directory server by default this will be the fully qualified container hostname provided
in docker-compose.yml or the hostname provided through the --hostname from `docker run`. A fully qualified hostname is required

DIR_ADMIN_USERNAME:  The username of the default admin account to be created in LDAP, will be `bladmin` if not specified  

DIR_ADMIN_PASSWORD:  The password for the default admin account password, will be same as DIR_MANAGER_PASSWORD or `Admin123` if neither is specified  

DIR_ADMIN_UID:  The admin account uid  

DIR_MANAGER_PASSWORD:  The password for the Directory Manager, will be same as DIR_ADMIN_PASSWORD or `Admin123` if neither is specified  

DIR_SUFFIX:  The base DN of the directory instance (eg. "dc=example,dc=com"} default will be "dc=example,dc=com" if not specified  

DIR_USERS_HOME:  The top level directory where user accounts should be created. Default is "/home"  

DIR_USERS_SHELL:  The shell for user accounts.Default is "/bin/bash"  

# Volumes
To preserve configuration and data between restarts and recreating the container, the following volumes should be mounted

    /etc/dirsrv:  location where instance configuration data is stored. Must be empty initially  
    /var/lib/dirsrv:  database storage location. Must be empty initially  
    /var/log/dirsrv:  location where logs will be stored. Must be empty initially  
    /certs:  Certificate import directory. The image expects to find the following files in this directory
    
        server.key - X509 Private Key file in PEM format (mandatory)  
        server.crt - X509 Certificate file in PEM format (mandatory)  
        ca.pem - Public key of the Certificate Authority who signed the server certificate in PEM format (optional). 
        
        For TLS, Make sure ca.pem is recognized by the client  
        To update certificate and key files just replace those with new ones and restart the container.  
    
# Testing

    ldapsearch -x -ZZ -h localhost -D "cn=Directory Manager" -b "dc=example,dc=com" -W

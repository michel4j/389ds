#!/bin/bash
#
# Register default environment
#
export DIR_HOSTNAME=${DIR_HOSTNAME:-$(hostname --fqdn)}
export DIR_ADMIN_PASSWORD=${DIR_ADMIN_PASSWORD:-${DIR_MANAGER_PASSWORD:-"Admin123"}}
export DIR_ADMIN_USERNAME=${DIR_ADMIN_USERNAME:-"bladmin"}
export DIR_ADMIN_UID=${DIR_ADMIN_UID:-"15000"}
export DIR_MANAGER_PASSWORD=${DIR_MANAGER_PASSWORD:-${DIR_ADMIN_PASSWORD:-"Admin123"}}
export DIR_SUFFIX=${DIR_SUFFIX:-"dc=example,dc=com"}
export DIR_USERS_HOME=${DIR_USERS_HOME:-"/home"}
export DIR_USERS_SHELL=${DIR_USERS_SHELL:-"/bin/bash"}

#
# housekeeping variables
#
BASEDIR="/etc/dirsrv/slapd-dir"
LOGDIR="/var/log/dirsrv/slapd-dir"
LOCKDIR="/var/lock/dirsrv/slapd-dir"
RUNDIR="/var/run/dirsrv/"
CERT_CA="CA certificate"
CERT_NAME="Server-Cert"
ROOT_DN="cn=Directory Manager"
#
# Check and import Setup Certificates
#
check_import_certs() {
    cd ${BASEDIR} && {

        # if certificates exist generate temporary hash 
        if [[ -f /certs/server.key && -f /certs/server.crt ]]; then 
            sha1sum /certs/server.key /certs/server.crt > /tmp/certsum_new 
        
            # Check if certs have changed
            if cmp -s ${BASEDIR}/.certsum /tmp/certsum_new; then
                echo "Certificate Database is Up-to-date. "
            else
                echo "Certificates have changed, re-creating certificate database ... "
                # cleanup and reinitialize certificate db
                /bin/cp /tmp/certsum_new ${BASEDIR}/.certsum
                echo > pwdfile.txt
                rm *.db -f
                certutil -N --empty-password -d "$BASEDIR"
                
                # recognize certificate authority if available
                if [ -f /certs/ca.pem ]; then
                    certutil -d ${BASEDIR} -A -n ${CERT_CA} -t "CT,," -a -i /certs/ca.pem
                fi  
                
                # convert and import certificate   
                openssl pkcs12 -export -inkey /certs/server.key -in /certs/server.crt -out /certs/server.p12 -nodes -name ${CERT_NAME} -password file:${BASEDIR}/pwdfile.txt
                pk12util -i /certs/server.p12 -d . -w ${BASEDIR}/pwdfile.txt
                /bin/rm -f /certs/server.p12                
            fi
        fi
    }
}

#
# Setup Directory instance
#
setup_dirsrv() {
    /bin/cp -rp /etc/dirsrv-tmpl/* /etc/dirsrv
    /sbin/setup-ds.pl -s -f /389ds-setup.inf --debug &&
    /bin/rm -f /389ds-setup.inf
    /bin/mv /certmap.conf ${BASEDIR}
}

#
# Load initial data and configuration 
#
init_config() {
    # need slapd running to import data and load initial data and configuration
    ns-slapd -D $BASEDIR && sleep 5  
    ldapadd -x -D"$ROOT_DN" -w${DIR_MANAGER_PASSWORD} -f /init-users.ldif &&
    ldapmodify -x -D"$ROOT_DN" -w${DIR_MANAGER_PASSWORD} -f /init-ssl.ldif &&
    /bin/rm -f /init-users.ldif /init-ssl.ldif 
    pkill -f ns-slapd  && sleep 5
}

#
# Make sure lock and run directories are avaiable if recreating container with existing instance setup
#
if [ ! -d ${LOCKDIR} ]; then
    mkdir -p ${RUNDIR} && chown -R nobody:nobody ${RUNDIR}
    mkdir -p ${LOCKDIR} && chown -R nobody:nobody ${LOCKDIR}
fi

#
# Setup instance if not already setup
#
if [ ! -d ${BASEDIR} ]; then
    # generate configuration and setup instance
    /confd -onetime -backend env
    setup_dirsrv       
    check_import_certs
    init_config
else
    check_import_certs
fi


exec /usr/sbin/ns-slapd -D ${BASEDIR} -d 0

#/usr/sbin/ns-slapd -D ${BASEDIR} && tail -F $LOGDIR/{access,errors} --max-unchanged-stats=5



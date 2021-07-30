#!/bin/bash

HOSTNAME=`hostname -f`
NO_AUTH=${NO_AUTH:-N}
TRUST_NETWORK=${TRUST_NETWORK:-10.0.0.0/16}
SMTP_USER=${SMTP_USER:-noreply}

if [[ ! -z ${SMTP_PASSWORD_FILE} && -f ${SMTP_PASSWORD_FILE} ]]
then
    SMTP_PASSWORD=`cat ${SMTP_PASSWORD_FILE}`
fi

cd /etc/postfix

if [[ "${NO_AUTH}" == "Y" ]]
then
    echo "NO_AUTH = Y. Postfix will not require authentication."
    postconf -e "mynetworks = 127.0.0.0/8 [::ffff:127.0.0.0]/104 [::1]/128 ${TRUST_NETWORK}"
else
    echo "SASL configuration..."
    # saslauthd
    postconf -e 'smtpd_sasl_local_domain = $myhostname'
    postconf -e 'smtpd_sasl_auth_enable = yes'
    postconf -e 'smtpd_sasl_service = smtpd'
    postconf -e 'smtpd_sasl_security_options = noanonymous'
    postconf -e 'broken_sasl_auth_clients = yes'
    postconf -e 'smtpd_recipient_restrictions = permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination'
    postconf -e 'inet_interfaces = all'

    echo 'pwcheck_method: saslauthd' > /etc/postfix/sasl/smtpd.conf
    echo 'mech_list: plain login'  >> /etc/postfix/sasl/smtpd.conf
    echo

    echo "Sasl configuration..."
    sed -i 's/START=.*/START=yes/' /etc/default/saslauthd
    sed -i '/START=.*/a PWDIR="/var/spool/postfix/var/run/saslauthd"' /etc/default/saslauthd
    sed -i '/PWDIR=.*/a PARAMS="-m ${PWDIR}"' /etc/default/saslauthd
    sed -i '/PARAMS=.*/a PIDFILE="${PWDIR}/saslauthd.pid"' /etc/default/saslauthd
    sed -i 's/^OPTIONS=.*//' /etc/default/saslauthd
    sed -i '$a OPTIONS="-c -m /var/spool/postfix/var/run/saslauthd"' /etc/default/saslauthd
    dpkg-statoverride --force-all --update --add root sasl 755 /var/spool/postfix/var/run/saslauthd
    echo

    echo "PAM configuration..."
    echo "smtp" > /etc/postfix/sasl-group.allowed
    
    echo "auth required pam_listfile.so onerr=fail item=group sense=allow file=/etc/postfix/sasl-group.allowed" > /etc/pam.d/smtpd
    echo "@include common-auth" >> /etc/pam.d/smtpd
    echo "@include common-account" >> /etc/pam.d/smtpd
    echo "@include common-password" >> /etc/pam.d/smtpd
    echo "@include common-session" >> /etc/pam.d/smtpd
    echo

    if [ -z ${SMTP_PASSWORD} ]
    then
        SMTP_PASSWORD=`openssl rand -base64 12`
        echo "SMTP_PASSWORD: ${SMTP_PASSWORD}"
    fi

    useradd -G smtp ${SMTP_USER}
    echo ${SMTP_USER}:${SMTP_PASSWORD} | chpasswd

    /etc/init.d/saslauthd start
fi

postconf -e "myhostname = ${HOSTNAME}"
postconf -e 'maillog_file = /dev/stdout'
postconf -e 'mydestination = localhost.localdomain, localhost'

cp /etc/host.conf /etc/hosts /etc/nsswitch.conf /etc/resolv.conf /etc/services /var/spool/postfix/etc
echo ${HOSTNAME} > /etc/mailname

/usr/sbin/postfix start-fg

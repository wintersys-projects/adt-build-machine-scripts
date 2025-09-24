BUILD_HOME="`/bin/cat /home/buildhome.dat`"
CLOUDHOST="`${BUILD_HOME}/helperscripts/GetVariableValue.sh CLOUDHOST`"
BUILD_IDENTIFIER="`${BUILD_HOME}/helperscripts/GetVariableValue.sh BUILD_IDENTIFIER`"

if ( [ "`/usr/bin/crontab -l | /bin/grep InitialiseNewSSLCertificate.sh | /bin/grep -"w ${BUILD_IDENTIFIER}" | /bin/grep -w "${CLOUDHOST}"`" = "" ] )
then
        /bin/echo '*/1 * * * * '${BUILD_HOME}'/initscripts/InitialiseNewSSLCertificate.sh "none" "none" "'${BUILD_IDENTIFIER}'" '"${CLOUDHOST}'"'' >> /var/spool/cron/crontabs/root
        /usr/bin/crontab -u root /var/spool/cron/crontabs/root 2>/dev/null
fi

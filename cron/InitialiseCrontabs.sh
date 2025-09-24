if ( [ ! -f /var/spool/cron/crontabs/root ] )
then
        /bin/touch /var/spool/cron/crontabs/root
fi


BUILD_HOME="`/bin/cat /home/buildhome.dat`"

${BUILD_HOME}/cron/InitialiseBuildMachineFirewallCron.sh
${BUILD_HOME}/cron/InitialiseUpdateAndUpgradeFromCron.sh
${BUILD_HOME}/cron/InitialiseRenewSSLCertificateCron.sh

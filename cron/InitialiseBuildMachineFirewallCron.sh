if ( [ "`/usr/bin/crontab -l | /bin/grep TightenBuildMachineFirewall.sh`" = "" ] )
then
        /bin/echo "*/1 * * * * ${BUILD_HOME}/security/firewall/TightenBuildMachineFirewall.sh" >> /var/spool/cron/crontabs/root
        /usr/bin/crontab -u root /var/spool/cron/crontabs/root 2>/dev/null
fi

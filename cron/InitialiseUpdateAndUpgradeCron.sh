if ( [ "`/usr/bin/crontab -l | /bin/grep 'apt' | /bin/grep 'update' | /bin/grep 'upgrade'`" = "" ] )
then
        /bin/echo "45 4 * * * /usr/bin/apt -y -qq update && /usr/bin/apt -y -qq upgrade && /usr/sbin/shutdown -r now" >> /var/spool/cron/crontabs/root
fi

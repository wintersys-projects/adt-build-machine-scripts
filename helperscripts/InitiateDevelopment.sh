/bin/echo "Please enter the username for the git account where your repositories are hosted"
read username

/bin/echo "Please enter the name of the branch that you wish to clone"
read branch

/bin/echo "Which provider are your adt infrastructure repositories hosted with?"
/bin/echo "1) Github 2) Bitbucket 3) GitLab"
read provider

while ( [ "`/bin/echo 1 2 3 | /bin/grep ${provider}`" = "" ] )
do
        /bin/echo "That is not a valid provider, please try again"
        read provider
done

if ( [ "${[provider}" = "1" ] )
then
        provider="github.com"
elif ( [ "${[provider}" = "2" ] )
then
        provider="bitbucket.org"
elif ( [ "${[provider}" = "3" ] )
then
        provider="gitlab.com"
fi


BUILD_HOME="`/bin/cat /home/buildhome.dat`"

if ( [ ! -d ${BUILD_HOME}/development ] )
then
        /bin/mkdir -p ${BUILD_HOME}/development/autoscaler
        /bin/mkdir -p ${BUILD_HOME}/development/webserver
        /bin/mkdir -p ${BUILD_HOME}/development/database
fi

/bin/echo "USERNAME:${username}" > ${BUILD_HOME}/development/.config
/bin/echo "BRANCH:${branch}" >> ${BUILD_HOME}/development/.config
/bin/echo "PROVIDER:${provider}" >> ${BUILD_HOME}/development/.config


/usr/bin/git clone  -b ${branch} --single-branch https://${provider}/${username}/adt-autoscaler-scripts.git ${BUILD_HOME}/development/autoscaler
/usr/bin/git clone  -b ${branch} --single-branch https://${provider}/${username}/adt-webserver-scripts.git ${BUILD_HOME}/development/webserver
/usr/bin/git clone  -b ${branch} --single-branch https://${provider}/${username}/adt-database-scripts.git ${BUILD_HOME}/development/database

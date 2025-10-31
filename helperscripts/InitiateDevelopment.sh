/bin/echo "Please enter the username for the git account where your repositories are hosted"
read username

/bin/echo "Please enter the name of the branch that you wish to clone"
read branch

BUILD_HOME="`/bin/cat /home/buildhome.dat`"

if ( [ ! -d ${BUILD_HOME}/development ] )
then
        /bin/mkdir -p ${BUILD_HOME}/development/autoscaler
        /bin/mkdir -p ${BUILD_HOME}/development/webserver
        /bin/mkdir -p ${BUILD_HOME}/development/database
fi

/bin/echo "USERNAME:${username}" > ${BUILD_HOME}/development/.config
/bin/echo "BRANCH:${branch}" >> ${BUILD_HOME}/development/.config

/usr/bin/git clone  -b ${branch} --single-branch https://github.com/${username}/adt-autoscaler-scripts.git ${BUILD_HOME}/development/autoscaler
/usr/bin/git clone  -b ${branch} --single-branch https://github.com/${username}/adt-webserver-scripts.git ${BUILD_HOME}/development/webserver
/usr/bin/git clone  -b ${branch} --single-branch https://github.com/${username}/adt-database-scripts.git ${BUILD_HOME}/development/database

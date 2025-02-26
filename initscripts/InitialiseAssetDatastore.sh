set -x
status () {
        /bin/echo "$1" | /usr/bin/tee /dev/fd/3 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
DIRECTORIES_TO_MOUNT="`${BUILD_HOME}/helperscripts/GetVariableValue.sh DIRECTORIES_TO_MOUNT | /bin/sed 's/:/ /g'`"
PERSIST_ASSETS_TO_CLOUD="`${BUILD_HOME}/helperscripts/GetVariableValue.sh PERSIST_ASSETS_TO_CLOUD`"
WEBSITE_URL="`${BUILD_HOME}/helperscripts/GetVariableValue.sh WEBSITE_URL`"

if ( [ "${PERSIST_ASSETS_TO_CLOUD}" = "1" ] )
then
        interrogation_home="${BUILD_HOME}/interrogation/tmp/backup"
        for directory_to_mount in ${DIRECTORIES_TO_MOUNT}
        do
                if ( [ "${directory_to_mount}" = "WHOLE-WEBROOT" ] )
                then
                        subdir=""
                else
                        subdir="${directory_to_mount}"
                fi
                directory_to_mount="`/bin/echo ${directory_to_mount} | /usr/bin/tr '[:upper:]' '[:lower:]'`"
                asset_datastore="`/bin/echo ${WEBSITE_URL} | /bin/sed 's/\./-/g'`-assets-${directory_to_mount}"

                ${BUILD_HOME}/providerscripts/datastore/MountDatastore.sh "${asset_datastore}"

                if ( [ ! -z "`/bin/ls ${interrogation_home}/${subdir}`" ] )
                then
                        ${BUILD_HOME}/providerscripts/datastore/SyncDatastore.sh ${interrogation_home}/${subdir} ${asset_datastore}
                fi

        done
fi

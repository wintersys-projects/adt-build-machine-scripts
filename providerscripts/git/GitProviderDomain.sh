status () {
        /bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
        script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
        /bin/echo "${script_name}: ${1}" >> /dev/fd/4
}

infrastructure_repository_provider="${1}"

if ( [ "${infrastructure_repository_provider}" = "github" ] )
then
    /bin/echo "github.com"
fi
if ( [ "${infrastructure_repository_provider}" = "bitbucket" ] )
then
    /bin/echo "bitbucket.org"
fi
if ( [ "${infrastructure_repository_provider}" = "gitlab" ] )
then
    /bin/echo "gitlab.com"
fi

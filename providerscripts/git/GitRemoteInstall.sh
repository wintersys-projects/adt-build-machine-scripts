#!/bin/sh

status () {
        /bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
        /bin/echo "${0}: ${1}" >> /dev/fd/4
}

if ( [ ! -f /usr/bin/git ] )
then
	DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=60 -qq -y update
	DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=60 -qq -y install git
fi

count="0"
while ( [ ! -f /usr/bin/git ] && [ "${count}" -lt "5" ] )
do
	DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=60 -qq -y update
	DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get -o DPkg::Lock::Timeout=60 -qq -y install git
	/bin/sleep 10
	count="`/usr/bin/expr ${count} + 1`"
done

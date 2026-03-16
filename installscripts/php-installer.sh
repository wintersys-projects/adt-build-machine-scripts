#!/bin/sh
# To add this repository please do:

if [ "$(whoami)" != "root" ]; then
    SUDO=/usr/bin/sudo
fi

${SUDO} /usr/bin/apt-get update
${SUDO} /usr/bin/apt-get -y install lsb-release ca-certificates curl
${SUDO} /usr/bin/curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
${SUDO} /usr/bin/dpkg -i /tmp/debsuryorg-archive-keyring.deb
${SUDO} /bin/sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
${SUDO} /usr/bin/apt-get update

#its possible we might fail and die, I have seen it happen due to networking glitches therefore php deserves a second chance just like everyone else
while ( [ -f /usr/bin/php ] )
do
    ${SUDO} /usr/bin/apt-get update
    ${SUDO} /usr/bin/apt-get -y install lsb-release ca-certificates curl
    ${SUDO} /usr/bin/curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
    ${SUDO} /usr/bin/dpkg -i /tmp/debsuryorg-archive-keyring.deb
    ${SUDO} /bin/sh -c 'echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
    ${SUDO} /usr/bin/apt-get update
done

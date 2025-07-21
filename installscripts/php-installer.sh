#!/bin/sh
# To add this repository please do:

if [ "$(whoami)" != "root" ]; then
    SUDO=/usr/bin/sudo
fi

${SUDO} apt-get update
${SUDO} apt-get -y install lsb-release ca-certificates curl
${SUDO} curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
${SUDO} dpkg -i /tmp/debsuryorg-archive-keyring.deb
${SUDO} sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
${SUDO} apt-get update

#!/bin/sh
######################################################################################################
# Description: This script will install the Vultr CLI toolkit
# Author: Peter Winter
# Date: 17/01/2017
#######################################################################################################
# License Agreement:
# This file is part of The Agile Deployment Toolkit.
# The Agile Deployment Toolkit is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# The Agile Deployment Toolkit is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# You should have received a copy of the GNU General Public License
# along with The Agile Deployment Toolkit.  If not, see <http://www.gnu.org/licenses/>.
#######################################################################################################
#######################################################################################################
#set -x

if ( [ "${1}" != "" ] )
then
    buildos="${1}"
fi

if ( [ "${buildos}" = "ubuntu" ] )
then 
    vultr_cli_version="`/usr/bin/curl -L https://api.github.com/repos/vultr/vultr-cli/releases/latest | /usr/bin/jq -r '.name'`"
    /usr/bin/wget -c https://github.com/vultr/vultr-cli/releases/download/${vultr_cli_version}/vultr-cli_${vultr_cli_version}_linux_amd64.tar.gz -O- | /usr/bin/tar -xz -C /usr/bin
    /bin/mv /usr/bin/vultr-cli /usr/bin/vultr
    /bin/chown root:root /usr/bin/vultr
fi

if ( [ "${buildos}" = "debian" ] )
then
    vultr_cli_version="`/usr/bin/curl -L https://api.github.com/repos/vultr/vultr-cli/releases/latest | /usr/bin/jq -r '.name'`"
    /usr/bin/wget -c https://github.com/vultr/vultr-cli/releases/download/${vultr_cli_version}/vultr-cli_${vultr_cli_version}_linux_amd64.tar.gz -O- | /usr/bin/tar -xz -C /usr/bin
    /bin/mv /usr/bin/vultr-cli /usr/bin/vultr
    /bin/chown root:root /usr/bin/vultr
fi

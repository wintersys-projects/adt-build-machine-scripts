#!/bin/sh
#########################################################################################
# Author : Peter Winter
# Date   : 13/07/2016
# Description : This toolkit will need uninterrupted ssh connections for extended periods of time
# so we can make that so by doing the below
#########################################################################################
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
#########################################################################################
#########################################################################################
#set -x

BUILD_HOME="`/bin/cat /home/buildhome.dat`"

/bin/echo "Host *" > ${HOME}/.ssh/config
/bin/echo "ServerAliveInterval 240" >> ${HOME}/.ssh/config
/bin/echo "ServerAliveCountMax 2" >> ${HOME}/.ssh/config

/bin/chmod 600 ${HOME}/.ssh/config

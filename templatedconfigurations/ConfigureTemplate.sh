#!/bin/sh
###################################################################################
# Description : This script lets the deployer choose a template to deploy from.
# There are various default templates for different types of build (virgin, baseline
# temporal) and so on
# Author: Peter Winter
# Date  : 13/07/2020
###################################################################################
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
####################################################################################
####################################################################################
#set -x

status () {
	/bin/echo "${1}" | /usr/bin/tee /dev/fd/3 2>/dev/null
	script_name="`/bin/echo ${0} | /usr/bin/awk -F'/' '{print $NF}'`"
	/bin/echo "${script_name}: ${1}" | /usr/bin/tee -a /dev/fd/4 2>/dev/null
}

BUILD_HOME="`/bin/cat /home/buildhome.dat`"
cloudhost="${1}"
build_identifier="${2}"
selected_template="${3}"

if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] && [ ! -f /root/PARAMETER ] )
then
	status ""
	status "I have the following templates available for ${cloudhost}"
	status ""
	numberoftemplates="`/bin/ls -l ${BUILD_HOME}/templatedconfigurations/templates/${cloudhost}/*.tmpl | /usr/bin/wc -l`"
	if ( [ "${numberoftemplates}" = "0" ] )
	then
		status "There are no templates available, you will need to configure an appropriate template before the build can proceed"
		status "Terminating this attempt...."
		/bin/touch /tmp/END_IT_ALL
	fi
	status "######################################################################"
	status "There are ${numberoftemplates} available template(s) for ${cloudhost}"
	status "######################################################################"
	status "" 
	status "You can use one of these default templates or you can make your own and place it in the ${BUILD_HOME}/templatedconfigurations/templates/${cloudhost} directory"
	status "with the nomenclature, ${cloudhost}[templatenumber].tmpl"
	status "" 
	status "#############AVAILABLE TEMPLATES#####################"

	/bin/ls -l ${BUILD_HOME}/templatedconfigurations/templates/${cloudhost} | /bin/grep ".tmpl$" | /usr/bin/awk '{print NR  "> " $s}' | /usr/bin/awk '{print $NF}' > /tmp/templates

	/usr/bin/sort -V -o /tmp/sortedtemplates /tmp/templates

	templateid="1"
	status "You can edit these templates directly if you wish to alter the configurations"
	for template in `/bin/cat /tmp/sortedtemplates`
	do
		status "###############################################################################################################"
		status "Template ID ${templateid}: ${template}"
		status "-----------------------------------------"
		templatebasename="`/bin/echo ${template} | /bin/sed 's/\.tmpl//g'`"
		templatefile="${BUILD_HOME}/templatedconfigurations/templates/${cloudhost}/${templatebasename}.tmpl"
		templatedescription="`/bin/cat ${BUILD_HOME}/templatedconfigurations/templates/${cloudhost}/${templatebasename}.description`"
		status ""
		status "Template File: ${templatefile}"
		status ""
		status "Description: ${templatedescription}"
		status ""
		status "Press the <enter> key to see the next template or enter the template ID (${templateID}) to select this current template"
		read response

		while ( [ "${response}" != "${templateid}" ]  && [ "${response}" != "" ] )
		do
			status "Sorry, that's not a valid input, try again..."
			read response
		done

		chosen="0"
		if ( [ "${response}" = "${templateid}" ] )
		then
			chosen="1"
			selectedtemplate=${templateid}
			break
		fi
		templateid="`/usr/bin/expr ${templateid} + 1`"
	done 

	if ( [ "${chosen}" = "0" ] )
	then
		status "#############AVAILABLE TEMPLATES#####################"
		status "Please enter a template number between 1 and ${numberoftemplates} to select the template that you want to use for the build process"
		read response
		wrong="1"
		selectedtemplate="0"
		while ( [ "${wrong}" = "1" ] )
		do
			if ( [ -n "${response}" ] && [ "${response}" -eq "${response}" ] 2>/dev/null )
			then
				if ( [ "${response}" -lt "1" ] || [ "${response}" -gt "${numberoftemplates}" ] )
				then
					wrong="1"
				else
					wrong="0"
					selectedtemplate="${response}"
				fi
			fi
			if ( [ "${wrong}" = "1" ] )
			then
				status "Sorry, that's not a valid template number. Please enter a number between 1 and ${numberoftemplates}"
				read response
			fi
		done
	fi

	status "You have selected template: ${selectedtemplate}"
	status "Press <enter> to continue"
	read x

	/bin/sh -n ${templatefile}

	if ( [ "$?" != "0" ] )
	then
		status "There is a problem (syntax error) with your template (${templatefile}) please correct it and try again...."
		/bin/touch /tmp/END_IT_ALL
	fi
elif ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" = "1" ] && [ ! -f /root/PARAMETER ] )
then
	. ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/build_environment
	templatefile="${BUILD_HOME}/templatedconfigurations/templates/${cloudhost}/${cloudhost}${selectedtemplate}.tmpl"

	if ( [ ! -d ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/hardcoretemplates ] )
	then
		/bin/mkdir -p  ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/hardcoretemplates
	fi

	if ( [ -f ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/hardcoretemplates/${cloudhost}${selectedtemplate}.tmpl ] )
	then
		/bin/mv ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/hardcoretemplates/${cloudhost}${selectedtemplate}.tmpl ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/hardcoretemplates/${cloudhost}${selectedtemplate}.tmpl.$$
	fi

	/bin/cp ${templatefile} ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/hardcoretemplates/${cloudhost}${selectedtemplate}.tmpl
	templatefile="${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}/hardcoretemplates/${cloudhost}${selectedtemplate}.tmpl"
	. ${BUILD_HOME}/templatedconfigurations/OverrideTemplate.sh
elif ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" = "1" ] && [ -f /root/PARAMETER ] )
then
	templatefile="${BUILD_HOME}/templatedconfigurations/templates/${cloudhost}/${cloudhost}${selected_template}.tmpl"
fi

/bin/sed -i '/BUILD_IDENTIFIER=/d' ${templatefile}
/bin/echo "export BUILD_IDENTIFIER=\"${build_identifier}\"" >> ${templatefile}

if ( [ "${cloudhost}" != "" ] )
then
	/bin/sed -i '/CLOUDHOST=/d' ${templatefile}
	/bin/echo "export CLOUDHOST=\"${cloudhost}\"" >> ${templatefile}
fi

#load the environment from the template file
. ${templatefile}

if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
then
	${BUILD_HOME}/templatedconfigurations/ValidateTemplate.sh ${templatefile}
fi

#Make it live
if ( [ ! -d ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier} ] )
then
	/bin/mkdir -p ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}
fi
/bin/cp ${templatefile} ${BUILD_HOME}/runtimedata/${cloudhost}/${build_identifier}
/bin/echo ${templatefile} > ${BUILD_HOME}/runtimedata/current_template_name


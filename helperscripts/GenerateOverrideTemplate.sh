#!/bin/sh
#######################################################################################################
# Author : Peter Winter
# Date   : 06/12/2020
# Description : With this script you can generate your template overrides init script interactively 
# rather than having to edit the template overrides file directly. Once this script has run, you can
# copy the scipt output into the userdata part of your build compute instance for your provider and it
# will spin up all the infrastructure for your build. 
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

if ( [ ! -f  ./GenerateOverrideTemplate.sh ] )
then
        /bin/echo "This script is expected to run from the helperscripts directory"
        exit
fi

text_reset="`/usr/bin/tput sgr0`"
green="`/usr/bin/tput setaf 2`"

/bin/echo "############################################################################################################"
/bin/echo "WARNING: THERE IS NO SANITY CHECKING IF YOU USE THIS SCRIPT WHICH MEANS THAT IF YOU ENTER ANYTHING INCORRECT"
/bin/echo "YOU WON'T FIND OUT ABOUT IT UNTIL YOU CONFIGURE A BUILD USING THE OUTPUT FROM THIS SCRIPT AND THE BUILD FAILS"
/bin/echo "AT THE END, THIS SCRIPT WILL OUTPUT ITS CONFIGURATION AND YOU CAN TAKE A COPY OF THE OUTPUT AND STORE IT ON YOUR LAPTOP OR DESKTOP"
/bin/echo "FOR USE IN CURRENT AND FUTURE DEPLOYMENTS"
/bin/echo "BE AWARE THAT THE OUTPUT GENERATED WILL CONTAIN SENSITIVE INFORMATION WHICH YOU NEED TO KEEP SECURE"
/bin/echo "############################################################################################################"
/bin/echo "Press <enter> to continue"
read x

BUILD_HOME="`/bin/cat /home/buildhome.dat`"

/bin/echo "Which Cloudhost are you using? 1) Digital Ocean 2) Exoscale 3) Linode 4) Vultr. Please Enter the number for your cloudhost"
read response
if ( [ "${response}" = "1" ] )
then
        CLOUDHOST="digitalocean"
elif ( [ "${response}" = "2" ] )
then
        CLOUDHOST="exoscale"
elif ( [ "${response}" = "3" ] )
then
        CLOUDHOST="linode"
elif ( [ "${response}" = "4" ] )
then
        CLOUDHOST="vultr"
else
        /bin/echo "Unrecognised  cloudhost. Exiting ...."
        exit
fi

/bin/echo "Please tell us which template you wish to override"
no_templates="`/usr/bin/wc -l ${BUILD_HOME}/templatedconfigurations/templates/${CLOUDHOST}/templatemenu.md | /usr/bin/awk '{print $1}'`"
/bin/cat ${BUILD_HOME}/templatedconfigurations/templates/${CLOUDHOST}/templatemenu.md
/bin/echo "Please input a number between 1 and ${no_templates} to select a template to override"
read choice
if ( [ "${choice}" -gt "0" ] && [ "${choice}" -le "${no_templates}" ] )
then 
        template="${choice}"
else
        /bin/echo "Invalid input...exiting"
        exit
fi
override_script="${BUILD_HOME}/templatedconfigurations/templates/${CLOUDHOST}/${CLOUDHOST}${template}.tmpl"
new_override_script="/tmp/${CLOUDHOST}${template}"

if ( [ -f ${new_override_script} ] )
then
        /bin/rm ${new_override_script}
fi

if ( [ -f ${new_override_script}.stack ] )
then
        /bin/rm ${new_override_script}.stack
fi

/bin/echo "# <UDF name=\"SELECTED_TEMPLATE\" label=\"The number of the template you are using\" />" >> ${new_override_script}.stack

/bin/echo "Press <enter to begin>"
read x

mandatory_processed="0"
prompt="1"

while ( [ "${mandatory_processed}" -lt "2" ] )
do
        while read line
        do
                if ( [ "${mandatory_processed}" = "0" ] )
                then
                        process_line="`/bin/echo ${line} | /bin/grep "MANDATORY" | /bin/grep "^export"`"
                else
                        process_line="`/bin/echo ${line} | /bin/grep -v "MANDATORY" | /bin/grep "^export" | /bin/grep -v 'NOT REQUIRED'`"
                fi

                if ( [ "${process_line}" != "" ] )
                then
                        live_variable="`/bin/echo ${line} | /usr/bin/awk -F'=' '{print $1}' | /usr/bin/awk '{print $2}'`"
                        current_value="`/bin/echo ${line} | /usr/bin/awk -F'"' '{print $2}'`"

                        if ( [ "${prompt}" = "1" ] )
                        then
                                /bin/echo "############################################################################################"
                                /bin/echo "Explanation from the specification regarding this variable:"
                                /bin/echo "############################################################################################"
                                /bin/sed "/### ${live_variable}/,/----/!d;/----/q" ${BUILD_HOME}/templatedconfigurations/specification.md
                                live_variable_green=`/bin/echo "${green}${live_variable}${text_reset}"` 
                                /bin/echo 'Found a variable "'${live_variable_green}'" what do you want to set it to?'
                                current_value="`/bin/grep -w "^export ${live_variable}=" ${override_script} | /usr/bin/awk -F'"' '"{print $2}"' | /usr/bin/awk -F'"' '{print $2}'`"
                                current_value_green=`/bin/echo "${green}${current_value}${text_reset}"` 
                                /bin/echo 'Its current value is "'${current_value_green}'" press <enter> to retain "reset" to erase, otherwise enter a new value now'
                                read setting < /dev/tty
                                /bin/echo "OK, thanks..."
                                /bin/echo
                                /bin/echo
                                /bin/echo
                                /bin/echo
                        fi

                        if ( [ "${setting}" != "" ] )
                        then
                                if ( [ "${setting}" = "reset" ] )
                                then
                                        setting=""
                                fi
                                /bin/echo 'export '${live_variable}'="'${setting}'"' >> ${new_override_script}
                                display_name="`/bin/echo ${live_variable} | /bin/sed 's/_/ /g'`"
                                if ( [ "${mandatory_processed}" = "0" ] )
                                then
                                        /bin/echo '# <UDF name="'${live_variable}'" label="'${display_name}'" />' >> ${new_override_script}.stack
                                else
                                        /bin/echo '# <UDF name="'${live_variable}'" label="'${display_name}'" default="'${setting}'" />' >> ${new_override_script}.stack
                                fi
                        else
                                /bin/echo 'export '${live_variable}'="'${current_value}'"' >> ${new_override_script}
                                display_name="`/bin/echo ${live_variable} | /bin/sed 's/_/ /g'`"
                                if ( [ "${mandatory_processed}" = "0" ] )
                                then
                                        /bin/echo '# <UDF name="'${live_variable}'" label="'${display_name}'" />' >> ${new_override_script}.stack
                                else
                                        /bin/echo '# <UDF name="'${live_variable}'" label="'${display_name}'" default="'${current_value}'" />' >> ${new_override_script}.stack
                                fi
                        fi
                fi
        done < ${override_script}

        if ( [ "${mandatory_processed}" = "0" ] )
        then
                /bin/echo "###################################################################################################################################"
                /bin/echo "Do you want to review the rest of the variables that are being used or do you want to accept the default template values"
                /bin/echo "If you want to change machine sizes or regions for example, you need to change them here so that they override the templated values"
                /bin/echo "###################################################################################################################################"
                /bin/echo "Enter 'y' or 'Y' if you wish to review/override the rest of the variables used by this template, 'N' or 'n' will use the default settings"
                read response

                while ( [ "`/bin/echo "Y y N n" | /bin/grep "${response}"`" = "" ] )
                do
                        /bin/echo "That is not a valid response, please try again....."
                        read response
                done

                if ( [ "${response}" != "y" ] && [ "${response}" != "Y" ] )
                then
                        prompt="0"
                fi
                if ( [ "${1}" = "stack" ] )
                then
                        /bin/echo "Variables marked mandatory written to ${new_override_script}.stack"
                        /bin/echo "##############################################################################" >> ${new_override_script}.stack
                else
                        /bin/echo "Variables marked mandatory written to ${new_override_script}"
                        /bin/echo "##############################################################################" >> ${new_override_script}
                fi
        fi
        mandatory_processed="`/usr/bin/expr ${mandatory_processed} + 1`"
done

if ( [ ! -d ${BUILD_HOME}/overridescripts ] )
then
        /bin/mkdir ${BUILD_HOME}/overridescripts
fi

if ( [ -f ${BUILD_HOME}/overridescripts/${CLOUDHOST}${template}override.tmpl ] )
then
        /bin/mv ${BUILD_HOME}/overridescripts/${CLOUDHOST}${template}override.tmpl  ${BUILD_HOME}/overridescripts/${CLOUDHOST}${template}override.tmpl.$$
fi

/bin/mv ${new_override_script} ${BUILD_HOME}/overridescripts/${CLOUDHOST}${template}override.tmpl
/bin/mv ${new_override_script}.stack ${BUILD_HOME}/overridescripts/${CLOUDHOST}${template}override.tmpl.stack

/bin/echo "About to validate the override script that has been generated. Press <enter to continue>"
read x

${BUILD_HOME}/templatedconfigurations/ValidateTemplate.sh ${BUILD_HOME}/overridescripts/${CLOUDHOST}${template}override.tmpl ${BUILD_HOME}

/bin/echo "######################################################################################################################"
/bin/echo "Cheers. Your configuration has been written to: ${BUILD_HOME}/overridescripts/${CLOUDHOST}${template}override.tmpl and ${BUILD_HOME}/overridescripts/${CLOUDHOST}${template}override.tmpl.stack "
/bin/echo "You should meticulously review this configuration file before deploying."
/bin/echo "You can edit and make changes to this configuration file as you desire but keep it with the same filename to deploy it"
/bin/echo "######################################################################################################################"

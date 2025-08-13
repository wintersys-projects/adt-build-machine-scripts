		response="INPUTNEW"

		if ( [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem ] && [ -f ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem ] )
		then
			status "There is a certificate I can use. Do you want me to use that?, or are you going to give me a new one?"
			status "Found a certificate for this domain. For your info, this is its expiry date"
			/usr/bin/openssl x509 -in ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem -noout -enddate
			status "Please enter Y to use the existing one. Anything else to input a new one"
			if ( [ "`${BUILD_HOME}/helperscripts/IsHardcoreBuild.sh`" != "1" ] )
			then
				read response
			fi
		fi
		if ( ( [ "${response}" != "Y" ] && [ "${response}" != "y" ] ) || [ "${response}" = "INPUTNEW" ] )
		then
			if ( [ ! -d ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL} ] )
			then
				/bin/mkdir -p ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}
			fi

			status "You have selected the manual method of generating an SSL certificate. This presumes that you have the necessary SSL files from a 3rd party"
			status "Certificate provider. So, here I will have to ask you to input the certificates so that I can pass them over to your servers"
			status "So, mate, please paste your certificate chain here. <ctrl d> when done"
			status "ESSENTIAL - Only copy from the first dash in the file '-' to the last dash in the file. Do not copy any prefixed whitespace or suffixed whitespace"

			fullchain=`cat`
			/bin/echo "${fullchain}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem
			/bin/chmod 400 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/fullchain.pem

			status "Cheers. So, mate, please paste your certifcate key here. <ctrl d> when done"
			status "ESSENTIAL - Only copy from the first dash in the file '-' to the last dash in the file. Do not copy any prefixed whitespace or suffixed whitespace"

			privkey=`cat`
			/bin/echo "${privkey}" > ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem
			/bin/chmod 400 ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${DNS_CHOICE}/${WEBSITE_URL}/privkey.pem

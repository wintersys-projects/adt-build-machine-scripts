1. As part of the pre-build process on the build-machine a test is made to see if these files already exist from a previous build


>     ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/fullchain.pem 
>     ${BUILD_HOME}/runtimedata/${CLOUDHOST}/${BUILD_IDENTIFIER}/ssl/${WEBSITE_URL}/privkey.pem 

If they exist then a check is made to see if they are valid certificates. If the certificates are valid they are copied to the datastore. If they are not valid then new certificates are generated and stored in these same files and then copied to the S3 datastore. A check is made to see that the certificates have copied successfully to the datastore. 

2. What 1. means is that at the end of the pre-build process SSL certificates will be available in the datastore which can be used by any webserver as its SSL certificate. When each webserver is built either the initial build process webserver or a webserver which has been built as part of an autoscaling event the certificate the certificates generated in 1. will be copied to the new webserver from the datastore and can then be used by that webserver as its SSL certificate. Each webserver stores its ssl certificates at 

>     ${HOME}/ssl/live/${WEBSITE_URL}/*.pem

3. There is a daily cron job which runs once a day to check certificate validation. If there are n webservers running then the webserver that "gets there first" checks the validity of its SSL certificate (which will be either valid or invalid for all n  webservers) and then if the existing certificate is found to be invalid, a new certificate is generated on the elected machine and is written to the S3 datastore. All the other webservers then copy the new certificate from the datastore to their own

>     ${HOME}/ssl/live/${WEBSITE_URL}/*.pem

If this system works correctly it should be a "hands off process" meaning that in normal operation you don't need to do anything to do with certificates because all of this manages it behind the scenes. 


if SSL_GENERATION_METHOD is set to MANUAL then the pre-build process will ask you for a certificate to use for the current build which you will have to obtain from your prefered third party certificate provider. If you use the manual SSL certificate approach you will have to manually update the certificates on your servers. The manual option is only really meant for an emergency if you can't get your certificate in the usual way. 

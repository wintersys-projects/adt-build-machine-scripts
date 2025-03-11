The autoscaling system is configured by writing a given number of webservers to scale to to the S3 datastore which can then be read by autoscaler machine(s) which then provision webservers accordingly to satisfy scaling requirements. 

To set how many webservers you want to deploy you have to use the script:

>     ${BUILD_HOME}/helperscripts/AdjustScaling.sh

1. If you follow the script and set the value to scale to to be 10, then, if there is one autoscaler machine running, then

>     STATIC_SCALE:10

will be written to the S3 datastore to be read by the autoscaler to tell it how many webservers to provision

2. If you then run the script again and set the number of webservers to 5 then 

>     STATIC_SCALE:5

will be written to the S3 datastore and that will be read by the autoscaler and it will scale down to 5 machines

3. If you run the script "AdjustScaling.sh" and set the number of webservers to "10" and there are 3 autoscaler machines running then:

>     STATIC_SCALE:4:3:3

will be written to the S3 Datastore and this will mean that autoscaler 1 will build out a total of 4 webservers, autoscaler 2 will build out 3 webservera and autoscaler 3 will build out 3 webservers. Having multiple autoscalers is not presumed to be for resource issues but rather for resilience issues. If one autoscaler fails there is another autoscaler that should still be running.

There is also the script

>     ${HOME}/providerscripts/utilities/processing/ScalingUpdateEvent.sh

available on each autoscaler that you can set up to be called from cron such that you configure scaling up and scaling down events for that webserver at specific times. If for example you wanted to scale up for the morning period scale down a bit at lunch time, scale up a bit in the afternoon and then scale down overnight then you could set up a set of time dependent calls to this script with your required webserver numbers. 

Your cron situation might look like:

>     30 8 * * *  export HOME="${HOME}" && ${HOME}/providerscripts/utilities/processing/ScalingUpdateEvent.sh 10"
>     00 12 * * *  export HOME="${HOME}" && ${HOME}/providerscripts/utilities/processing/ScalingUpdateEvent.sh 6"
>     00 14 * * *  export HOME="${HOME}" && ${HOME}/providerscripts/utilities/processing/ScalingUpdateEvent.sh 10"
>     30 17 * * *  export HOME="${HOME}" && ${HOME}/providerscripts/utilities/processing/ScalingUpdateEvent.sh 3"

If you want to scale up to 10 at 8:30AM scale down to 6 during a 2 hour lunch window, scale up to 10 again for the afternoon and then scale down to 3 overnight. 



How to adjust your scaling parameters

The autoscaling system works by writing a given number of webservers to scale to to the S3 datastore which can then be read by autoscaling machine(s) and provisioned accordingly to satisfy scaling requirements. 

To set how many webservers you want to deploy you have to use the script:

${BUILD_HOME}/helperscripts/AdjustScaling.sh

If you follow the script and set the value to scale to to be 10, then, if there is one autoscaler machine running, then

STATIC_SCALE:10 will be written to the S2 datastore to be read by the autoscaler to tell it how many webservers to provision

If you run the script again and set the number of autosclers to 5 then 

STATIC_SCALE:5 will be written to the S3 datastore and that will be read by the autoscaler and it will scale down to 5 machines

If you run the script "AdjustScaling.sh" again and set it to "10" webservers and there are 3 autoscaler machines running then:

STATIC_SCALE:4:3:3 will be written to the S3 Datastore and this will mean that autoscaler 1 will build out a total of 4 webservers, autoscaler 2 will build out 2 webservera and autoscaler 3 will build out 3 webservers.

There is also the script

${HOME}/providerscripts/utilities/processing/ScalingUpdateEvent.sh

available on each autoscaler that you can set up to be called from cron such that you configure scaling up and scaling down events for that webserver at specific times. If for example you wanted to scale up for the morning period scale down a bit at lunch time, scale up a bit in the afternoon and then scale down overnight then you could set up a set of time dependent calls to this script with your required webserver numbers. 

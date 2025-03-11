In production mode you should deploy at least 2 webservers for failover reasons but you can deploy as many as you want up to n webservers so to make your architecture resilent to machine failures you just need to deploy more than one webserver and the more webservers you deploy the more resilient it will be. 

For the database if you use one of the managed database offerings that the supported cloudhosts provide then those managed database offerings have fail safety in mind so that you can consider them resilent.

For your autoscalers, most likely you will only want to deploy one autoscaler for most uses but if you are very keen on having a fail safe system you can deploy more than one autoscaler so that if one autoscaler machine fails the other machines are there to take over. With more than one autoscaler machine the webserver fleet can scale up marginally more quickly.

To a certain extent I have taken account of resilience when I have designed this toolkit.  

If you wanted maximum resilience it might be possible to take these additional steps to what the toolkit provides by default.  

This is theoetical and maybe you will take it all the way.   

If you used a remote managed databasse  you could make one deployment of your webserver fleet to a particular region and you could make a second deployment to a  
second region using the same configuration (in other words, using same configurations for DNS provider and database in both deployments). You would likely want your 
communications between your webservers and your database to be encrypted. You will need to disable "PurgeDetachedIPs.sh" on your autoscalers.  
The DNS system will be updated with the webservers from both regions meaning requests will be routed to one region or the other based on DNS round robin selecting.  
The DNS system as it stands is a point of failure. If you want true resilience you could have it so that you configure a primary and secondary DNS provider.  
I don't know if you can detect when your primary DNS is down and reconfigure to use the secondary DNS but you could at least manually make configuration changes  
such that if you found your primary DNS was down you could reroute within minutes to a secondary DNS provider which you have preconfigured your system to take over  
if you had a DNS outage from your primary system.
Its theoretically possible that you could "half" of your webserver fleet running on digitalocean and half of it running on linode as long as performance was acceptable
and you had secured your connections to your mamaged database using encryption. Beyond that you could even have a third of your webservers running on digital ocean, a third
of them on exoscale and a third of them on linode. I haven't got round to trying out such lofty ideals with what I have built but it is theoretically a way of building more 
resilence into things and getting more into distributed architectures and so on. As a database something like Amazon RDS has failover built into it.

So, by having the option of a preconfigured secondary DNS, webservers distributed over multiple providers and a managed database with failover built in and so on  
that might be a way of building this out as resilent as possible as far as I can see anyway. 

Anwway I don't want to run before I can walk at the time or writing this toolkit hasn't even been used "in the live" yet so that would be the frist step perhaps. 

one caveat i can see if you deployed webservers to different vps provider is that if there was to be a software update of your webroot there needs to be some way of coordinating it betweem the providers using the common datastore

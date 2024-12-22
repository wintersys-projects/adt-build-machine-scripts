#### Arrangement 1

If you just have a single webserver with not many user generated assets then you can just have a webroot which is the disk of the VPS server that your webserver runs on.

```SYNC_WEBROOTS="0"```  
```DIRECTORIES_TO_MOUNT=""```  
```PERSIST_ASSETS_TO_CLOUD="0"```  

#### Arrangement 2

You can have arrangment 1 on multiple webservers and have the webroots synchronised. To switch on webroot synchronisation which means that updates to any of the webroots are synchronised in short order to all the other webroots in your system by having the following relevant settings in your template

```SYNC_WEBROOTS="1"```  
```DIRECTORIES_TO_MOUNT=""```  
```PERSIST_ASSETS_TO_CLOUD="0"```  

#### Arrangment 3

You have a lot of user generated assets and multiple webroots/webserver machines in your architecture. To run with that configuration you need to have the following settings. If your application is a joomla application then you will likely have user assets generated in the "images" directory and so that configuration will be arranged like this. When assets are peristed to the cloud that means that they are written to the object store and mounted into your webroot. This is not ideal but it is a solution. Your first preference should be to offload your user generated assets to an object store at an application level using a plugin or an extension of some sort but if that is not possible you can get by like this in a lot of cases. 

```SYNC_WEBROOTS="1"```  
```DIRECTORIES_TO_MOUNT="images"```  
```PERSIST_ASSETS_TO_CLOUD="1"```  

#### Arrangement 4

Its possible that VPS providers are going to start supporting proper shared filesystems. What this means is that you have one filesystem and that all the different webservers share (and therefore update) the same filesystem. In this case there is no need to sync webroots and if you have got deep pockets there's not even any need to use the cheaper S3 object storage solution for your assets. If shared filesystems do become available for the VPS hosts that my toolkit supports, then, I will update the toolkit to support shared filesystems which will most probabaly just be a case of creating the filesystem and mounting it as the webroot on each webserver. If that method is supported (and it will be more expensive but also more performant for you if it is an option) then the toolkit will need to be configured in the following way:

```SYNC_WEBROOTS="0"```  
```DIRECTORIES_TO_MOUNT=""```  
```PERSIST_ASSETS_TO_CLOUD=""```  

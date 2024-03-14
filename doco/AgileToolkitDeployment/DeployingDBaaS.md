It is required that if you want to spin up a managed database that you use an expedited or hardcore build style and follow the steps outlined below 
At the current time, managed databases are not supported using the interactive method of starting an Expedited Build
The managed database you describe here will spin up automatically through the build process

### Digital Ocean

If you are using digital ocean managed databases you can set the following in your template or override

##### DATABASE_DBaaS_INSTALLATION_TYPE="\<db-type\>:DBAAS:\<db-engine\>:\<region\>:\<size\>:\<db-version\>:\<cluster-name\>:\<db-name\>"  
##### DATABASE_INSTALLATION_TYPE="DBaaS"
  
So an example of this would be in your template or override:

    1. DATABASE_DBaaS_INSTALLATION_TYPE="MySQL:DBAAS:mysql:lon1:1:db-s-1vcpu-1gb:8:testdbcluster1:testdb1"
    2. DATABASE_DBaaS_INSTALLATION_TYPE="Postgres:DBAAS:pg:lon1:1:db-s-1vcpu-1gb:8:testdbcluster1:testdb1"

So, for the first example:  
  
db-type="MySQL"  
db-engine="mysql"  
region="lon1"  
size="db-s-1vcpu-1gb"  
db-version="8"  (mysql 8)  
cluster-name="testdbcluster1"  
db-name="testdb1"  
  
So,  
  
  **db-type** can be: **"MySQL", "Postgres"**  
  **db-engine** can be **"mysql", "pg"**  
  **region** can be **"nyc1, sfo1, nyc2, ams2, sgp1, lon1, nyc3, ams3, fra1, tor1, sfo2, blr1, sfo3"**  
  **size** can be **"db-s-1vcpu-1gb", "db-s-1vcpu-2gb", "db-s-1vcpu-3gb", "db-s-2vcpu-4gb", "db-s-4vcpu-8gb", "db-s-8vcpu-16gb", "db-s-8vcpu-32gb"**  
  **db-version** can be for **mysql = "8"** for **postgres="13"**  
  **cluster-name** can be unique string for your cluster, for example, **"testcluster"**   
  **db-name** can be a unique string for your database, for example, **"testdatabase"** 
  
--------
  
### Exoscale
  
If you are using exoscale managed databases you can set the following in your template or override

##### DATABASE_DBaaS_INSTALLATION_TYPE="\<db-type\>:DBAAS:\<db-engine\>:\<region\>:\<size\>:\<db-name\>"  
##### DATABASE_INSTALLATION_TYPE="DBaaS"  

So an example of this would be in your template or override: 

    1. DATABASE_DBaaS_INSTALLATION_TYPE="MySQL:DBAAS:mysql:ch-gva-2:hobbyist-2:testdb1"  
    2. DATABASE_DBaaS_INSTALLATION_TYPE="Postgres:DBAAS:pg:ch-gva-2:hobbyist-2:testdb1"  
  
So, for the first example:  
  
db-type="MySQL"  
db-engine="mysql"  
region="ch-gva-2"  
size="hobbyist-2"  
db-name="testdb1" 

So,  
  
  **db-type** can be: **"MySQL", "Postgres"**  
  **db-engine** can be **"mysql", "pg"**  
  **region** can be **"ch-gva-2", "de-fra-1", "de-muc-1", "at-vie-1", "ch-dk-2", "bg-sof-1"**  
  **size** can be **"hobbyist-2", "startup-[4|8|16|32|64|128|255]", "business-[4|8|16|32|64|128|255]", "premium-[4|8|16|32|64|128|255]"**  
  **db-name** can be a unique string for your database, for example, **"testdatabase"**  
  
  ----------
  
  ### Linode (at this time Dec 2023, Linode/Akamai are reworking their DBaaS solution and its not currently available for use)
  
  If you are using Linode Managed Databases you can set the following in your template override:
  
  ##### DATABASE_DBaaS_INSTALLATION_TYPE="\<db-type\>:DBAAS:\<db-engine\>:\<region\>:\<machine-size\>:\<cluster-size\>"  
  ##### DATABASE_INSTALLATION_TYPE="DBaaS" 
  
  So, an example of this in your template or override would be:
  
    1. DATABASE_DBaaS_INSTALLATION_TYPE="MySQL:DBAAS:mysql/8.0.26:eu-west:g6-nanode-1:1"

  Therefore, for example 1, 
  
  db-type="MySQL"
  db-engine="mysql/8.0.26"
  region="eu-west"
  machine-size="g6-nanode-1"
  cluster-size="1"
  
  db-type can be **"MySQL"**  
  
  db-engine can be **"mysql/8.0.26"** or **"mysql/5.7.30"** - at the time of writing you can check what engines are available for you by issuing **"linode-cli databases engines"** command.  
  
  region can be **"ap-west,ca-central,ap-southeast,us-central,us-west,us-southeast,us-east,eu-west,ap-south,eu-central,ap-northeast"  
  
  machine-size=**"g6-nanode-1,g6-standard-1,g6-standard-2,g6-standard-4,g6-standard-6,g6-standard-8,g6-standard-16,g6-standard-20,g6-standard-24,g6-standard-32,g7-highmem-1,g7-highmem-2,g7-highmem-4,g7-highmem-8,g7-highmem-16,g6-dedicated-2,g6-dedicated-4,g6-dedicated-8,g6-dedicated-16,g6-dedicated-32,g6-dedicated-48,g6-dedicated-50,g6-dedicated-56,g6-dedicated-64"**  
  
  cluster-size, as far as I know, can be **1** or **3**  
  
    2. DATABASE_DBaaS_INSTALLATION_TYPE="Postgres:DBAAS:postgresql/14.4:eu-west:g6-nanode-1:1"

  Therefore, for example 1, 
  
  db-type="Postgres"
  db-engine="postgresql/14.4"
  region="eu-west"
  machine-size="g6-nanode-1"
  cluster-size="1"
  
  db-type can be **"Postgres"**  
  
  db-engine can be **"postgresql/10.14"** or **"postgresql/11.15"** or **"postgresql/12.10"** or **"postgresql/13.2"** or **"postgresql/14.4"**  - at the time of writing you can check what engines are available for you by issuing **"linode-cli databases engines"** command.  
  
  region can be **"ap-west,ca-central,ap-southeast,us-central,us-west,us-southeast,us-east,eu-west,ap-south,eu-central,ap-northeast"  
  
  machine-size=**"g6-nanode-1,g6-standard-1,g6-standard-2,g6-standard-4,g6-standard-6,g6-standard-8,g6-standard-16,g6-standard-20,g6-standard-24,g6-standard-32,g7-highmem-1,g7-highmem-2,g7-highmem-4,g7-highmem-8,g7-highmem-16,g6-dedicated-2,g6-dedicated-4,g6-dedicated-8,g6-dedicated-16,g6-dedicated-32,g6-dedicated-48,g6-dedicated-50,g6-dedicated-56,g6-dedicated-64"**  
  
  cluster-size, as far as I know, can be **1** or **3** 
  
  
  When using linode you will be prompted for other variables such as database name, hostname of the database and so on, which you have to get from the GUI system because as far as I know, they are not accessible through the CLI.   
  
  
  -------------------
  
  ### VULTR
  
  If you are using Vultr Managed Databases you can set the following in your template override:
 
  ##### DATABASE_DBaaS_INSTALLATION_TYPE="\<db-type\>:DBAAS:\<db-engine\>:\<db-engine-version\>:\<region\>:\<machine-size\>:\<db-name\>:\<cluster-name>"  
  ##### DATABASE_INSTALLATION_TYPE="DBaaS" 
  
  Example 1:
  
  DATABASE_DBaaS_INSTALLATION_TYPE="MySQL:DBAAS:mysql:8:lhr:vultr-dbaas-hobbyist-cc-1-25-1:testdb:TestDatabase" 

  db-type = MySQL  
  db-engine = mysql  
  db-engine-version = 8  
  region = lhr  
  machine-size = vultr-dbaas-hobbyist-cc-1-25-1  
  db-name = testdb  
  cluster-name = TestDatabase  
  
  Example 2:  
  
  DATABASE_DBaaS_INSTALLATION_TYPE="Postgres:DBAAS:pg:14:lhr:vultr-dbaas-hobbyist-cc-1-25-1:testdb:TestDatabase" 

  db-type = Postgres  
  db-engine = pg  
  db-engine-version = 14   
  region = lhr  
  machine-size = vultr-dbaas-hobbyist-cc-1-25-1  
  db-name = testdb  
  cluster-name = TestDatabase  


  db-type can be "MySQL" or "Postgres"   
  
  db-engine = mysql db-engine-version=8  or db-engine=pg db-engine-version=11 or 12 or 13 or 14 or 15    
 
  region = ams atl blr bom cdg del dfw ewr fra hnl icn itm jnb lax lhr mad mel mex mia nrt ord sao scl sea sgp sjc sto syd waw yto    
 
  machine-size =  vultr-dbaas-hobbyist-cc-1-25-1 vultr-dbaas-startup-cc-1-55-2 vultr-dbaas-business-cc-1-55-2 vultr-dbaas-premium-cc-1-55-2 vultr-dbaas-startup-cc-2-80-4 vultr-dbaas-business-cc-2-80-4 vultr-dbaas-premium-cc-2-80-4 vultr-dbaas-startup-cc-4-160-8 vultr-dbaas-business-cc-4-160-8 vultr-dbaas-premium-cc-4-160-8 
  
  ### AWS  
  
  If you are using AWS Managed Databases you can set the following in your template or override:  
  
  ##### DATABASE_DBaaS_INSTALLATION_TYPE="\<db-type\>:DBAAS:\<db-engine\>:\<region\>:\<size\>:\<db-name\>:\<db-identifier\>:\<storage-capacity\>:\<db-username\>:\<db-password\>"  
  ##### DATABASE_INSTALLATION_TYPE="DBaaS"  
  
  So an example of this would be in your template or override:  

     1. DATABASE_DBaaS_INSTALLATION_TYPE="MySQL:DBAAS:mysql:eu-west-1b:db.t3.micro:TestDatabase:testdb:20:testdatabaseuser:ghdbRtjh=g"  
     2. DATABASE_DBaaS_INSTALLATION_TYPE="Maria:DBAAS:mariadb:eu-west-1b:db.t3.micro:TestDatabase:testdb:20:testdatabaseuser:ghdbRtjh=g"   
     3. DATABASE_DBaaS_INSTALLATION_TYPE="Postgres:DBAAS:postgres:eu-west-1a:db.t3.micro:TestDatabase:testdb:20:testdatabaseuser:ghdbRtjh=g"  
  
  So, for the first example:  
  
  db-type="MySQL"  
  db-engine="mysql"  
  region="eu-west-1b"  
  size="db.t3.micro"  
  db-name="TestDatabase"  
  db-identifier="testdb4"  
  storage-capacity="20"  
  db-username="testdatabaseuser"  
  db-password="ghdbRtjh=g"
  
  **db-type** can be: **"MySQL", "Postgres"**    
  
  **db-engine** can be: **"mysql", "postgresql"**   
  
  **region** can be:  
  **us-east-1a,us-east-1b,us-east-1c,us-east-1d,us-east-1e,us-east-1f,us-west-2a,us-west-2b,us-west-2c,us-west-1a,us-west-1b,eu-west-1a,eu-west-1b,eu-west-1c,eu-central-1a,eu-central-1b,ap-southeast-1a,ap-southeast-1b,ap-southeast-2a,ap-southeast-2b,ap-southeast-2c,ap-northeast-1a,ap-northeast-1c,sa-east-1a,sa-east-1b,sa-east-1c,ap-south-1a,ap-south-1b**   
  
  **size** can be: **"db.t3.micro,db.t3.small,db.t3.medium,db.t3.large,db.t3.xlarge,db.t3.2xlarge"**   
  
  **db-name** can be a descriptive name for your database, for example, **"TestDatabase"** (note, must be no spaces in the db-name parameter)    
  
  **db-identifier** can be a unique string for your database, for example, **"testdb4"**  (do not use any upper case letters for the db-identifier)  
  
  **storage-capacity** disk storage capacity of your database, for example, **"20"** for 20GB   
  
  **db-username** the username for your database for example, **"testdatabaseuser"**   
  
  **db-password** the password for your database for example, **"ghdbRtjh=g""**    
  

  

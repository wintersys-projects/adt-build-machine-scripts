As far as I know Joomla currently only allows the usage of port 5432 when using Postgres as your database.
This means that if you are using a managed DB service you will need to change the default port that the managed database supplies you with
to be 5432 when you are deploying joomla to a Postgres database otherwise you will get a timeout because only port 5432 is allowed by Joomla.
As far as I know with some managed database offerings its not possible to change the port that the database vendor has provided for you. 

Correct me if I am wrong and any updated info or work around on the Joomla side about how Joomla can be deployed to use ad-hoc ports when connecting to Postgres would be cool to know. At the moment, this toolkit prompts the user if they have set a port to something other than 5432 when deploying Joomla to the Postgres database. 

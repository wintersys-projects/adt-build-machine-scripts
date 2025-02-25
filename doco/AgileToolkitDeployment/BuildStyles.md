The file 

>     ${BUILD_HOME}/builddescriptors/buildstyles.dat

is where the different pieces of software that you have requested to install through your template.
If your template is configured to install NGINX then you can configure NGINX to install in a variety of ways as described below:

---------------------------------------------------------

If you set NGINX to install using cloud-init

>     NGINX:cloud-init

Behind the scenes, NGINX will be installed by the simple command

>     packages:
>       - nginx

What this will do is install the cloud-init version of nginx

When you choose the cloud-init way of installing NGINX you can also configure various settings from this file. For example, you can set
>     NGINX:settings:client_body_timeout=15:client_header_timeout=20:keepalive_timeout=10:keepalive_requests=100:reset_timedout_connection=on

--------------------------------------------------------------
If you set NGINX to install using repo

>     NGINX:repo

Behind the scenes, NGINX will be installed using apt-get or apt-fast

When you choose the repo way of installing NGINX you can also install additional dynamic modules. For example, you can set
>     NGINX:modules-list:mpm_event:ssl:rewrite:expires:headers:proxyproxy_http:remoteip:proxy_fcgi

When you choose the repo way of installing NGINX you can also configure various settings from this file. For example, you can set
>     NGINX:settings:client_body_timeout=15:client_header_timeout=20:keepalive_timeout=10:keepalive_requests=100:reset_timedout_connection=on

-------------------------------------------------------------

If you set NGINX to install from source

>     NGINX:source

Behind the scenes, NGINX will be installed by downloading the very lastest stable version of the NGINX sourcecode and compiling it

When you choose the source way of installing NGINX you can also install additional dynamic modules. For example, you can set
>     NGINX:modules-list:http-image-filter

When you choose the source way of installing NGINX you can also install additional built in static modules. For example, you can set
>     NGINX:static-modules-list:select:poll:http_ssl:http_v2:http_realip:http_addition:http_sub:http_dav:http_flv:http_mp4:http_gunzip:http_gzip_static:http_auth_request:http_random_index:http_secure_link:http_degradation:http_slice:http_stub_status:stream_ssl_preread:mail_ssl:stream_ssl:stream_realip:ngx_http_realip_module

When you choose the source way of installing NGINX you can also configure various settings from this file. For example, you can set
>     NGINX:settings:client_body_timeout=15:client_header_timeout=20:keepalive_timeout=10:keepalive_requests=100:reset_timedout_connection=on

When you build NGINX from source there will be additional software packages that need to be installed because the compilation process depends on them. You can set the software packages to install as follows:
>     NGINX:software-packages:build-essential:libpcre3-dev:libssl-dev:zlib1g-dev:libgd-dev:libnginx-mod-http-image-filter

NOTE:
the configuration setting 
>     NGINX:modules-list:http-image-filter

requires the configuration setting to install the module
>     NGINX:software-packages:libnginx-mod-http-image-filter

and you will need to do this for any dynamic module that you want to add

-------------------------------------------------------------------

If your template is configured to install APACHE then you can configure APACHE to install in a variety of ways as described below:


If you set APACHE to install using cloud-init

>     APACHE:cloud-init

Behind the scenes, APACHE will be installed by the simple command

>     packages:
>       - apache2

What this will do is install the cloud-init version of nginx

When you choose the cloud-init way of installing APACHE you can also configure various settings from this file. For example, you can set
>     APACHE:settings:StartServers=4:MinSpareServers=20:MaxSpareServers=40:MaxRequestWorkers=200:MaxConnectionsPerChild=4500

--------------------------------------------------------------
If you set APACHE to install using repo

>     APACHE:repo

Behind the scenes, APACHE will be installed using apt-get or apt-fast

When you choose the repo way of installing APACHE you can also install additional dynamic modules. For example, you can set
>     APACHE:modules-list:mpm_event:ssl:rewrite:expires:headers:proxy:proxy_http:remoteip:proxy_fcgi

When you choose the repo way of installing APACHE you can also configure various settings from this file. For example, you can set
>     APACHE:settings:StartServers=4:MinSpareServers=20:MaxSpareServers=40:MaxRequestWorkers=200:MaxConnectionsPerChild=4500

-------------------------------------------------------------

If you set APACHE to install from source

>     APACHE:source

Behind the scenes, APACHE will be installed by downloading the very lastest stable version of the APACHE sourcecode and compiling it

When you choose the source way of installing APACHE you can also install additional dynamic modules. For example, you can set
>     APACHE:modules-list:ssl:rewrite:expires:headers:proxy:proxy_http:remoteip:proxy_fcgi:socache_shmcb:log_config:log_debug:logio:dir:unixd:authz_core:mime:http2

When you choose the source way of installing APACHE you can also install additional built in static modules. For example, you can set
>     APACHE:static-modules-list:mpm_event

When you choose the source way of installing APACHE you can also configure various settings from this file. For example, you can set
>     APACHE:settings:StartServers=4:MinSpareServers=20:MaxSpareServers=40:MaxRequestWorkers=200:MaxConnectionsPerChild=4500

When you build APACHE from source there will be additional software packages that need to be installed because the compilation process depends on them. You can set the software packages to install as follows:
>     APACHE:software-packages:pandoc:build-essential:libssl-dev:libexpat-dev:libpcre3-dev:libapr1-dev:libaprutil1-dev:libnghttp2-dev:lua5.4:libjansson-dev:libcurl4-gnutls-dev

-------------------------------------------------------------------


If your template is configured to install LIGHTTPD then you can configure LIGHTTPD to install in a variety of ways as described below:


If you set LIGHTTPD to install using cloud-init

>     LIGHTTPD:cloud-init

Behind the scenes, LIGHTTPD will be installed by the simple command

>     packages:
>       - lighttpd

What this will do is install the cloud-init version of lighttpd

When you choose the cloud-init way of installing LIGHTTPD you can also configure various settings from this file. For example, you can set
>     LIGHTTPD:settings:server.use-ipv6="disable":server.bind="localhost":server.max-fds=2048:server.stat-cache-engine="simple"

--------------------------------------------------------------
If you set LIGHTTPD to install using repo

>     LIGHTTPD:repo

Behind the scenes, LIGHTTPD will be installed using apt-get or apt-fast

When you choose the repo way of installing LIGHTTPD you can also install additional dynamic modules. For example, you can set
>     LIGHTTPD:modules-list:mod_indexfile:mod_access:mod_accesslog:mod_alias:mod_redirect:mod_auth:mod_deflate:mod_openssl:mod_dirlisting:mod_proxy:mod_fastcgi:mod_staticfile:mod_expire:mod_ssi:mod_userdir:mod_status:mod_setenv:mod_rewrite:mod_indexfile:mod_authn_file

When you choose the repo way of installing LIGHTTPD you can also configure various settings from this file. For example, you can set
>     LIGHTTPD:settings:server.use-ipv6="disable":server.bind="localhost":server.max-fds=2048:server.stat-cache-engine="simple"

-------------------------------------------------------------

If you set LIGHTTPD to install from source

>     LIGHTTPD:source

Behind the scenes, LIGHTTPD will be installed by downloading the very lastest stable version of the LIGHTTPD sourcecode and compiling it

When you choose the source way of installing LIGHTTPD you can also install additional dynamic modules. For example, you can set
>     LIGHTTPD:modules-list:mod_indexfile:mod_access:mod_accesslog:mod_alias:mod_redirect:mod_auth:mod_deflate:mod_openssl:mod_dirlisting:mod_proxy:mod_fastcgi:mod_staticfile:mod_expire:mod_ssi:mod_userdir:mod_status:mod_setenv:mod_rewrite:mod_indexfile:mod_authn_file

When you choose the source way of installing LIGHTTPD you can also install additional built in static modules. For example, you can set
>     LIGHTTPD:static-modules-list:zlib:libxml:openssl:gnutls

When you choose the source way of installing LIGHTTPD you can also configure various settings from this file. For example, you can set
>     LIGHTTPD:settings:server.use-ipv6='disable':server.bind='localhost':server.max-fds=2048:server.stat-cache-engine='simple'

When you build LIGHTTPD from source there will be additional software packages that need to be installed because the compilation process depends on them. You can set the software packages to install as follows:
>     LIGHTTPD:software-packages:autoconf:automake:libtool:m4:pkg-config:build-essential:libpcre3-dev:libpcre2-dev:zlib1g:zlib1g-dev:libssl-dev:libgnutls28-dev

-------------------------------------------------------------------

If your template is configured to install php  then you can set the php extensions that will be installed here as well as set whether to use a socket of a port for php-fpm (note php-fpm is always installed when you install PHP, you  don't need to explicitly reference php-fpm here).

>     cloud-init install technique

When you put this in the buildstyles.dat file it will install cli,simplexml,dom,gd,intl,zip,mysqli,curl  extensions using port 9176. This will install php using cloud-init 

>     PHP:cloud-init:cli:simplexml:dom:gd:intl:zip:mysqli:curl|9176

When you put this in the buildstyles.dat file it will install cli,dom,gd,intl,zip,mysqli,curl  extensions using a socket to communicate. This will install php using cloud-init 

>     PHP:cloud-init:cli:dom:gd:intl:zip:mysqli:curl|9176

apt-get install technique

When you put this in the buildstyles.dat file it will install soap,mysqli and gd php extensions using port 9176. This will install php using apt-get which means you are free to customise the method of installation if you want to

>     PHP:soap:mysqli:gd|9176

When you put this in the buildstyles.dat file it will install pgsql,curl,zip and gd  php extensions using port 9176 using a socket file to communicate. This will install php using apt-get.

>     PHP:pgsql:curl:zip:gd

You can also configure the php pool through this file. For example, you can set:

>     CONFIGPHPPOOL:pm=ondemand:pm.max_children=4:pm.max_requests=200:pm.start_servers=10:pm.min_spare_servers=5:
>     pm.max_spare_servers=20:pm.process_idle_timeout=10s

You can also configure the php.ini through this file. For example, you can set:

>     CONFIGPHPINI:upload_max_filesize=64M:post_max_size=64M:max_input_vars=5000:zlib.output_compression=On:
>     cgi.fix_pathinfo=0:output_buffering=Off:disable_functions=exec,passthru,shell_exec,system,proc_open,popen,parse_ini_file,show_source:
>     allow_url_fopen=Off:allow_url_include=Off:memory_limit=256M:opcache.enable=1:opcache.memory_consumption=256:
>     open_basedir=/var/##/tmp:upload_tmp_dir=/var/www/html/tmp

NOTE that when there are multiple separate terms/values the token ## is the delimiter

-----------------------------------------------------------------

You can decide which datastore mount tool to install and how as follows:

>     DATASTOREMOUNTTOOL:rclone:repo if you want to install rclone as your datastore mount tool
>     DATASTOREMOUNTTOOL:s3fs:repo if you want to install s3fs as your datastore mount tool
>     DATASTOREMOUNTTOOL:goof:binary if you want to install goofys as your datastore mount tool
>     DATASTOREMOUNTTOOL:geesefs:binary if you want to install geesefs as your datastore mount tool

If you want to install these tools in a different way such as from source and so on you are free to modify the toolkit

-----------------------------------------------------------------

#Note, "MySQL" isn't configurable through this file only Maria DB is

If your template is configured to install mariadb you can install it as follows:
>     MARIADB:cloud-init
to install the current version

and to install a specific version by apt-get
>     MARIADB:repo:11.5.2

-------------------------------------------------------------------

If your template is configured to install postgres you can install it as follows:
>     POSTGRES:cloud-init
to install the current version

and to install a specific version by apt-get
>     POSTGRES:repo:17

--------------------------------------------------------------------

To set the build chain style, set it here. You can modify the toolkit to support different build chain types if you wanted a build chain that included a caching system or something
>     BUILDCHAINTYPE:standard

---------------------------------------------------------------------

You can choose which datastore tool you want to install here by choosing one of these:

>     DATASTORETOOL:s3cmd:repo
>     DATASTORETOOL:s5cmd:binary

---------------------------------------------------------------------

You can chose to use different package managers as follows:

>     PACKAGEMANAGER:apt
>     PACKAGEMANAGER:apt-fast

---------------------------------------------------------------------

You can use ufw or iptables as your firewalling type

>     FIREWALL:ufw
>     FIREWALL:iptables

-------------------------------------------------------------------
How system emails can be sent can be set here:

>     EMAILUTIL:sendemail
>     EMAILUTIL:mail

--------

NOTE: I support cloud-init style installs as well as apt-get style installs because apt-get is more customisable and I found that cloud-init wasn't always an option because when PHP8.4 was new at least, it couldn't be installed with cloud-init so I had the option of falling back to the apt-get method to get it installed and I didn't know how to install MySQL using cloud-init either and so in that case I could fall back to the apt-get or apt-fast install method and still be up and running. Most likely in the future there might be other scenarios where cloud-init package install isn't an option and so having the option to fall back to apt-get saves the day.

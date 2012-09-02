#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
webroot="/home/wwwroot/"
nginxvhost="/etc/nginx/conf.d/"

# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script!"
    exit 1
fi

clear
echo "============================="
echo "Nginx+uwsgi app quick setup"
echo "You must have nginx+uwsgi installed first!"
echo "============================="

domain="ichon.me"
echo "Please input domain name:"
read -p "(default:ichon.me):" domain
if [ "$domain" = "" ];then
	domain="ichon.me"
fi
echo ""
project="djproject"
echo "Pleae input Django project name:"
read -p "(default:djproject):" project
if [ "$project" = "" ];then
	project="djproject"
fi
echo ""
prodir=${webroot}${project}
echo "============================="
echo "Your domain name is $domain"
echo "Your Django project is $project"
echo "Your project directory is $prodir"
echo "============================="
echo ""
get_char()
{
SAVEDSTTY=`stty -g`
stty -echo
stty cbreak
dd if=/dev/tty bs=1 count=1 2> /dev/null
stty -raw
stty echo
stty $SAVEDSTTY
}
echo ""
echo "Press any key to start..."
char=`get_char`

if [ ! -d $prodir ];then
	mkdir -p $prodir
fi

cat >${prodir}/wsgi_app.py <<eof
import os
os.environ['DJANGO_SETTINGS_MODULE'] = '${project}.settings'
import django.core.handlers.wsgi
application = django.core.handlers.wsgi.WSGIHandler()
eof

cat >${nginxvhost}${domain}.conf <<eof
server
	{
		listen	80;
		server_name ${domain};
		index index.html index.htm;
		root  ${prodir};

		location /
			{
				uwsgi_pass	unix:///tmp/uwsgi.sock;
				uwsgi_param	UWSGI_CHDIR	${prodir};
				uwsgi_param	UWSGI_SCRIPT	wsgi_app;
				include		uwsgi_params;
			}

		location ~ .*\.(gif|jpg|jpeg|png|bmp|swf)$
			{
				expires      30d;
			}

		location ~ .*\.(js|css)?$
			{
				expires      12h;
			}

		location ^~ /static/ 
			{
				alias ${prodir}/static/;
			}

	}
eof

/etc/init.d/nginx restart
/etc/init.d/uwsgi restart

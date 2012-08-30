#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script!"
    exit 1
fi

clear
echo "============================="
echo "Nginx+uwsgi quick install"
echo "You must have nginx installed first!"
echo "============================="

webroot="/home/wwwroot"
echo "Please input web root:"
read -p "(default:/home/wwwroot):" webroot
if [ "$webroot" = "" ];then
	webroot="/home/wwwroot"
fi
echo ""
echo "============================="
echo "web root is $webroot"
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

yum -y install python-pip
yum -y install python-devel

pip-python install django
pip-python install uwsgi

if [ ! -d $webroot ];then
	mkdir -p $webroot
fi

cat >/etc/init.d/uwsgi<<eof
#!/bin/sh
# chkconfig: 2345 85 15
# description: Startup script for uwsgi.
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
PIDFILE="/tmp/uwsgi.pid"
SOCKET="/tmp/uwsgi.sock"
LOG="/tmp/uwsgi.log"
WEBROOT=$webroot

set -e
do_start(){
	uwsgi -s \$SOCKET -C 666 -M -p 5 -t 30 -R 10000 --vhost -d \$LOG --pidfile \$PIDFILE --pythonpath \$WEBROOT
}
do_stop(){
	kill -2 \`cat -- \$PIDFILE\`
	rm -f -- \$PIDFILE
	rm -f -- \$SOCKET
}

case "\$1" in
 start)
 echo -n "Starting uwsgi..."
 do_start
 echo "done."
 ;;
 stop)
 echo -n "Stoping uwsgi..."
 do_stop
 echo "done."
 ;;
 restart)
 echo -n "Restarting uwsgi..."
 do_stop
 do_start
 echo "done."
 ;;
 *)
 echo "Usage: uwsgi {start|stop|restart}" >&2
 exit 3
 ;;
esac

exit 0
eof

chmod 755 /etc/init.d/uwsgi
chkconfig --add uwsgi
chkconfig --level 345 uwsgi on
/etc/init.d/uwsgi start

echo ""
if [ -e /tmp/uwsgi.pid ] && [ -e /tmp/uwsgi.sock ];
then
	echo "uwsgi installation completed."
else
	echo "uwsgi installation failed."
fi

#!/bin/sh
#
# inbucket     Inbucket email testing service
#
# chkconfig: 2345 80 30
# description: Inbucket is a disposable email service for testing email
#              functionality of other applications.
# processname: inbucket
# pidfile: /var/run/inbucket/inbucket.pid

### BEGIN INIT INFO
# Provides: Inbucket service
# Required-Start: $local_fs $network $remote_fs
# Required-Stop: $local_fs $network $remote_fs
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: start and stop inbucket
# Description: Inbucket is a disposable email service for testing email
#              functionality of other applications.
#              moves mail from one machine to another.
### END INIT INFO

# Source function library.
. /etc/rc.d/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

RETVAL=0
program=/opt/inbucket/inbucket
prog=${program##*/}
config=/etc/opt/inbucket.conf
runas=inbucket

lockfile=/var/lock/subsys/$prog
pidfile=/var/run/$prog/$prog.pid
logfile=/var/log/$prog.log

conf_check() {
    [ -x $program ] || exit 5
    [ -f $config ] || exit 6
}

perms_check() {
    mkdir -p /var/run/$prog
    chown $runas: /var/run/$prog
    touch $logfile
    chown $runas: $logfile
    # Allow bind to ports under 1024
    setcap 'cap_net_bind_service=+ep' $program
}

start() {
	[ "$EUID" != "0" ] && exit 4
	# Check that networking is up.
	[ ${NETWORKING} = "no" ] && exit 1
	# Check config sanity
	conf_check
	perms_check
	# Start daemon
	echo -n $"Starting $prog: "
	daemon --user $runas --pidfile $pidfile $program \
	  -pidfile $pidfile -logfile $logfile $config \&
	RETVAL=$?
	[ $RETVAL -eq 0 ] && touch $lockfile
        echo
	return $RETVAL
}

stop() {
	[ "$EUID" != "0" ] && exit 4
	conf_check
        # Stop daemon
	echo -n $"Shutting down $prog: "
	killproc -p "$pidfile" -d 15 "$program"
	RETVAL=$?
	[ $RETVAL -eq 0 ] && rm -f $lockfile $pidfile
	echo
	return $RETVAL
}

reload() {
	[ "$EUID" != "0" ] && exit 4
	echo -n $"Reloading $prog: "
	killproc -p "$pidfile" "$program" -HUP
	RETVAL=$?
	echo
	return $RETVAL
}

# See how we were called.
case "$1" in
  start)
	[ -e $lockfile ] && exit 0
	start
	;;
  stop)
	[ -e $lockfile ] || exit 0
	stop
	;;
  reload)
	[ -e $lockfile ] || exit 0
	reload
	;;
  restart|force-reload)
	stop
	start
	;;
  status)
  	status -p $pidfile -l $(basename $lockfile) $prog
	;;
  *)
	echo $"Usage: $0 {start|stop|restart|status}"
	exit 2
esac

exit $?

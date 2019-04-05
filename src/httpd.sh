#!/bin/sh

PIDFILE=/var/run/apache.pid

start() {
    nohup /usr/sbin/httpd -DFOREGROUND >/dev/null 2>&1 </dev/null &
    PID=$!
    echo $PID >$PIDFILE
    sleep 1
    kill -0 $PID >/dev/null 2>&1 || exit 1
}

stop() {
    if [ -f $PIDFILE ] ; then
        kill -WINCH `cat $PIDFILE`
        sleep 1
        rm -f $PIDFILE
    fi
    PIDS=`ps -ef  | grep http[d] | awk '{ print $2 }'`
    if [ "$PIDS" != "" ]; then
        kill -9 $PIDS
    fi
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        start
        ;;
esac

#!/bin/sh -x

PIDFILE=/var/run/apache.pid
RET=0

start() {
    RET=0
    nohup /usr/sbin/httpd -DFOREGROUND >/dev/null 2>&1 </dev/null &
    PID=$!
    echo $PID >$PIDFILE
    sleep 1
    kill -0 $PID >/dev/null 2>&1 || RET=1
}

stop() {
    RET=0
    if [ -f $PIDFILE ] ; then
        PIDS=`cat $PIDFILE`
        kill -TERM $PIDS
        for a in 1 2 3 4 5; do
            sleep 1
            kill -0 $PIDS >/dev/null 2>&1 || break;
        done
        rm -f $PIDFILE
    fi
    PIDS=`ps -ef  | grep /usr/sbin/httpd | grep -v grep | awk '{ print $2 }'`
    if [ "$PIDS" != "" ]; then
        RET=1
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

exit $RET


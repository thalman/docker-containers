#!/bin/bash
# Copyright (c) 2019 Tomas Halman. All rights reserved
#
# This work is licensed under the terms of the MIT license.
# For a copy, see <https://opensource.org/licenses/MIT>.

KEEPRUNNING=1
IDLE=
LOG=/var/log/boot.log

function dostartup() {
    echo "startup"
    echo -n "" >$LOG
    for service in /etc/rc.docker/* ; do
        if [ -x $service ] ; then
            echo -n "Starting $service ..."
            echo "-----------------------------------------------------" >>$LOG
            echo "Starting $service" >>$LOG
            echo "-----------------------------------------------------" >>$LOG
            $service start 2>&1 | tee -a $LOG /tmp/boot-output | awk '{ printf ("."); fflush(); }'
            RESULT=${PIPESTATUS[0]}
            if [ "$RESULT" = "0" ] ; then
                echo " [ OK ]"
            else
                echo " [FAIL]"
                cat /tmp/boot-output
            fi
            rm -f /tmp/boot-output
        fi
    done
    echo "startup completed"
}

function doshutdown() {
    echo "shutdown"
    for service in $(find /etc/rc.docker -type f -o -type l | sort --reverse) ; do
        if [ -x $service ] ; then
            echo -n "Stopping $service ..."
            $service stop >/dev/null 2>&1 | awk '{ printf ("."); fflush(); }'
            RESULT=${PIPESTATUS[0]}
            if [ "$RESULT" = "0" ] ; then
                echo "[ OK ]"
            else
                echo "[FAIL]"
            fi
        fi
    done
    KEEPRUNNING=0
    echo "shutdown completed"
    kill $IDLE
}

# trap 'do_shutdown' TERM
dostartup
trap 'doshutdown' TERM
trap 'doshutdown' INT

while [ $KEEPRUNNING = 1 ]; do
    if [ "$1" != "" ] ; then
	# got CMD
	"$@" &
    else
        # no CMD, just wait for signal
	tail -f /dev/null &
    fi
    IDLE=$!
    wait $IDLE
done

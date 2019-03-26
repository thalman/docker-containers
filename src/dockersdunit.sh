#!/bin/bash
# Copyright (c) 2019 Tomas Halman. All rights reserved
#
# This work is licensed under the terms of the MIT license.
# For a copy, see <https://opensource.org/licenses/MIT>.

RET=0

NAME=$(basename $0 .sh | sed -r -e 's/^[0-9]+-//')
SDUNIT=$(find /usr/lib/systemd  -type f -name $NAME.service | head -n 1)

if [ "$SDUNIT" = "" ] ; then
    echo "service unit for $SDUNIT not found!" >&2
    exit 1
fi

get_from_sdu() {
    grep -E -e "^$1=" <$SDUNIT | cut -d= -f2-
}

get_wd() {
    dir=$(get_from_sdu WorkingDirectory)
    if [ "$dir" = "" ] ; then
        echo .
        return
    fi
    home=$(getent passwd $USER | cut -d: -f6)
    echo "$dir" | sed -r -e "s#~#$home#"
}

case "$1" in
    start)
        CMD=$(get_from_sdu ExecStart)
        USER=$(get_from_sdu User)
        if [ "$USER" = "" ]; then
            USER=root
        fi
        su - $USER -s /bin/sh -c "cd $(get_wd); nohup $CMD >>/var/log/boot-$NAME 2>&1 &" </dev/null >/dev/null 2>&1
        sleep 1
        if [ "$(pidof $NAME)" = "" ] ; then
            RET=2
        fi
        ;;
    stop)
        PID=$(pidof $NAME)
        if [ "$PID" == "" ] ; then
            echo "$NAME is not running" >&2
            exit 1
        fi
        CMD=$(get_from_sdu ExecStop)
        if [ "$CMD" = "" ] ; then
            kill $PID
            STEP=0
            QUIT=360
            while [ "$STEP" != "$QUIT" ] ; do
                STEP=`expr $STEP + 1`
                sleep 1
                if [ $STEP = 5 ]; then
                    echo -n "Waiting for $NAME to shutdown"
                fi
                if [ $STEP -gt 5 ]; then
                    echo -n "."
                fi
                if [ "$(pidof $NAME)" = "" ] ; then
                    if [ $STEP -gt 4 ]; then
                        echo ""
                    fi
                    STEP=$QUIT
                fi
            done
            PID=$(pidof $NAME)
            if [ "$PID" != "" ] ; then
                echo ""
                echo "Process $NAME did not quit in $QUIT seconds, sending SIGKILL"
                pkill -SIGKILL -P $PID >/dev/null 2>&1
                kill -SIGKILL $PID >/dev/null 2>&1
            fi
        else
            $CMD
        fi
        RET=$?
        ;;
    restart)
        $0 stop
        $0 start
        RET=$?
        ;;
    *)
        echo "Invalid command! Use $(basename $0) (start|stop|restart)" >&2
        RET=1
        ;;
esac

exit $RET

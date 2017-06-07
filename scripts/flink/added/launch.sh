#!/bin/bash

function check_reverse_proxy {
    grep -e "^flink\.ui\.reverseProxy" $FLINK_HOME/conf/flink-defaults.conf &> /dev/null
    if [ "$?" -ne 0 ]; then
        echo "Appending default reverse proxy config to flink-defaults.conf"
        echo "flink.ui.reverseProxy              true" >> $FLINK_HOME/conf/flink-defaults.conf
        echo "flink.ui.reverseProxyUrl           /" >> $FLINK_HOME/conf/flink-defaults.conf
    fi
}

# If the UPDATE_FLINK_CONF_DIR dir is non-empty,
# copy the contents to $FLINK_HOME/conf
if [ -d "$UPDATE_FLINK_CONF_DIR" ]; then
    flinkconfs=$(ls -1 $UPDATE_FLINK_CONF_DIR | wc -l)
    if [ "$flinkconfs" -ne "0" ]; then
        echo "Copying from $UPDATE_FLINK_CONF_DIR to $FLINK_HOME/conf"
        ls -1 $UPDATE_FLINK_CONF_DIR
        cp $UPDATE_FLINK_CONF_DIR/* $FLINK_HOME/conf
    fi
elif [ -n "$UPDATE_FLINK_CONF_DIR" ]; then
    echo "Directory $UPDATE_FLINK_CONF_DIR does not exist, using default flink config"
fi

check_reverse_proxy

# If FLINK_MASTER_ADDRESS env varaible is not provided, start master,
# otherwise start worker and connect to FLINK_MASTER_ADDRESS
if [ -z ${FLINK_MASTER_ADDRESS+_} ]; then
    echo "Starting master"

    # run the flink master directly (instead of sbin/start-master.sh) to
    # link master and container lifecycle
    exec $FLINK_HOME/bin/flink-class org.apache.flink.deploy.master.Master
else
    echo "Starting worker, will connect to: $FLINK_MASTER_ADDRESS"
    while true; do
        echo "Waiting for flink master to be available ..."
        curl --connect-timeout 1 -s -X GET $FLINK_MASTER_UI_ADDRESS > /dev/null
        if [ $? -eq 0 ]; then
            break
        fi
        sleep 1
    done
    exec $FLINK_HOME/bin/flink-class org.apache.flink.deploy.worker.Worker $FLINK_MASTER_ADDRESS
fi


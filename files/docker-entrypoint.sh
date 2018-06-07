#!/bin/sh

###############################################################################
#  Licensed to the Apache Software Foundation (ASF) under one
#  or more contributor license agreements.  See the NOTICE file
#  distributed with this work for additional information
#  regarding copyright ownership.  The ASF licenses this file
#  to you under the Apache License, Version 2.0 (the
#  "License"); you may not use this file except in compliance
#  with the License.  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
# limitations under the License.
###############################################################################

# If unspecified, the hostname of the container is taken as the JobManager address
JOB_MANAGER_RPC_ADDRESS=${JOB_MANAGER_RPC_ADDRESS:-$(hostname -f)}

drop_privs_cmd() {
    if [ -x /sbin/su-exec ]; then
        # Alpine
        echo su-exec
    else
        # Others
        echo gosu
    fi
}

if [ "$1" = "help" ]; then
    echo "Usage: $(basename "$0") (jobmanager|taskmanager|local|help)"
    exit 0

elif [ "$1" = "jobmanager" ]; then
    sed -i -e "s/jobmanager.rpc.address: localhost/jobmanager.rpc.address: ${JOB_MANAGER_RPC_ADDRESS}/g" "$FLINK_HOME/conf/flink-conf.yaml"
    sed -i -e "s/jobmanager.heap.mb: 1024/jobmanager.heap.mb: ${JOB_MANAGER_HEAP_MB}/g" "$FLINK_HOME/conf/flink-conf.yaml"
    sed -i -e "s/# state.backend: filesystem/state.backend: filesystem/g" "$FLINK_HOME/conf/flink-conf.yaml"
    sed -i -e "s~# state.backend.fs.checkpointdir: hdfs://namenode-host:port/flink-checkpoints~state.backend.fs.checkpointdir: file://${CHECKPOINT_DIR}~g" "$FLINK_HOME/conf/flink-conf.yaml"
    echo "state.checkpoints.dir: ${CHECKPOINT_DIR}/metadata" >> "$FLINK_HOME/conf/flink-conf.yaml"
    echo "blob.server.port: 6124" >> "$FLINK_HOME/conf/flink-conf.yaml"
    echo "query.server.port: 6125" >> "$FLINK_HOME/conf/flink-conf.yaml"
    echo "akka.ask.timeout: 120 s" >> "$FLINK_HOME/conf/flink-conf.yaml"
    echo "config file: " && grep '^[^\n#]' "$FLINK_HOME/conf/flink-conf.yaml"

    echo "Starting Job Manager"
    exec $(drop_privs_cmd) flink "$FLINK_HOME/bin/jobmanager.sh" start-foreground cluster

elif [ "$1" = "taskmanager" ]; then
    TASK_MANAGER_NUMBER_OF_TASK_SLOTS=${TASK_MANAGER_NUMBER_OF_TASK_SLOTS:-$(grep -c ^processor /proc/cpuinfo)}
    sed -i -e "s/jobmanager.rpc.address: localhost/jobmanager.rpc.address: ${JOB_MANAGER_RPC_ADDRESS}/g" "$FLINK_HOME/conf/flink-conf.yaml"
    sed -i -e "s/taskmanager.numberOfTaskSlots: 1/taskmanager.numberOfTaskSlots: $TASK_MANAGER_NUMBER_OF_TASK_SLOTS/g" "$FLINK_HOME/conf/flink-conf.yaml"
    sed -i -e "s/taskmanager.heap.mb: 1024/taskmanager.heap.mb: ${TASK_MANAGER_HEAP_MB}/g" "$FLINK_HOME/conf/flink-conf.yaml"
    sed -i -e "s/# state.backend: filesystem/state.backend: filesystem/g" "$FLINK_HOME/conf/flink-conf.yaml"
    sed -i -e "s~# state.backend.fs.checkpointdir: hdfs://namenode-host:port/flink-checkpoints~state.backend.fs.checkpointdir: file://${CHECKPOINT_DIR}~g" "$FLINK_HOME/conf/flink-conf.yaml"
    echo "state.checkpoints.dir: ${CHECKPOINT_DIR}/metadata" >> "$FLINK_HOME/conf/flink-conf.yaml"
    echo "blob.server.port: 6124" >> "$FLINK_HOME/conf/flink-conf.yaml"
    echo "query.server.port: 6125" >> "$FLINK_HOME/conf/flink-conf.yaml"
    echo "akka.ask.timeout: 120 s" >> "$FLINK_HOME/conf/flink-conf.yaml"
    echo "config file: " && grep '^[^\n#]' "$FLINK_HOME/conf/flink-conf.yaml"

    echo "Starting Task Manager"
    exec $(drop_privs_cmd) flink "$FLINK_HOME/bin/taskmanager.sh" start-foreground

elif [ "$1" = "local" ]; then
    echo "Starting local cluster"
    exec $(drop_privs_cmd) flink "$FLINK_HOME/bin/jobmanager.sh" start-foreground local
fi

exec "$@"

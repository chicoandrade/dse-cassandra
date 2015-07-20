#!/bin/bash

CONFIG_DIR=$DSE_HOME/resources/cassandra/conf/
TEMPLATE_FILE=$CONFIG_DIR/template.yaml
CONFIG_FILE=$CONFIG_DIR/cassandra.yaml
JMX_USER=cassandra
JMX_PASSWORD=cassandra

LOCAL_IP=$(ifconfig eth0|grep addr:1|grep inet|awk '{print $2}'|cut -d':' -f2)
echo "listen_address: $LOCAL_IP" >> $TEMPLATE_FILE

if [ -z "$SOLR" ];
then
  SOLR_OPTION=-s
else
  SOLR_OPTION=
fi

if [ -z "$SPARK" ];
then
  SPARK_OPTION=-s
else
  SPARK_OPTION=
fi

: ${CASSANDRA_LISTEN_ADDRESS='auto'}
if [ "$CASSANDRA_LISTEN_ADDRESS" = 'auto' ]; then
  CASSANDRA_LISTEN_ADDRESS="$(hostname --ip-address)"
fi

: ${CASSANDRA_BROADCAST_ADDRESS="$CASSANDRA_LISTEN_ADDRESS"}

if [ "$CASSANDRA_BROADCAST_ADDRESS" = 'auto' ]; then
  CASSANDRA_BROADCAST_ADDRESS="$(hostname --ip-address)"
fi
: ${CASSANDRA_BROADCAST_RPC_ADDRESS:=$CASSANDRA_BROADCAST_ADDRESS}

if [ "$CASSANDRA_SEEDS" ]; then
  CASSANDRA_SEEDS="$CASSANDRA_SEEDS"
else
  CASSANDRA_SEEDS="$CASSANDRA_BROADCAST_ADDRESS"
fi

if [ ! "$CASSANDRA_CLUSTER_NAME" ]; then
  CASSANDRA_CLUSTER_NAME="Test Cluster"
fi

sed -ri 's/(- seeds:) "127.0.0.1"/\1 "'"$CASSANDRA_SEEDS"'"/' "$TEMPLATE_FILE"
sed -ri 's/AllowAllAuthenticator/PasswordAuthenticator/' "$TEMPLATE_FILE"
sed -ri 's/Test Cluster/$CASSANDRA_CLUSTER_NAME/' "$TEMPLATE_FILE"

sed -i 's/LOCAL_JMX=yes/LOCAL_JMX=no/g' "$CONFIG_DIR/cassandra-env.sh"
cp "/usr/lib/jvm/java-1.7.0-openjdk-amd64/jre/lib/management/jmxremote.password" "$CONFIG_DIR/jmxremote.password"
chmod 400 "$CONFIG_DIR/jmxremote.password"
echo "$JMX_USER $JMX_PASSWORD" >> "$CONFIG_DIR/jmxremote.password"
sed -i "/^monitorRole/a\\${JMX_USER} readwrite" "/usr/lib/jvm/java-1.7.0-openjdk-amd64/jre/lib/management/jmxremote.access"

for yaml in \
  broadcast_address \
  broadcast_rpc_address \
  cluster_name \
  endpoint_snitch \
  listen_address \
  num_tokens \
; do
  var="CASSANDRA_${yaml^^}"
  val="${!var}"
  if [ "$val" ]; then
    sed -ri 's/^(# )?('"$yaml"':).*/\2 '"$val"'/' "$TEMPLATE_FILE"
  fi
done

for rackdc in dc rack; do
  var="CASSANDRA_${rackdc^^}"
  val="${!var}"
  if [ "$val" ]; then
    sed -ri 's/^('"$rackdc"'=).*/\1 '"$val"'/' "$CONFIG_DIR/cassandra-rackdc.properties"
  fi
done

cat $TEMPLATE_FILE > $CONFIG_FILE

if [ -z "$MANUAL" ];
then
  $DSE_HOME/bin/dse cassandra -f $SPARK_OPTION $SOLR_OPTION
fi
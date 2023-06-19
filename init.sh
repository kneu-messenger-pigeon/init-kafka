#!/usr/bin/env sh
# blocks until kafka is reachable
set -e
NEXT_WAIT_TIME=0
until [ $NEXT_WAIT_TIME -eq 5 ] || kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --list; do
    sleep $(( NEXT_WAIT_TIME++ ))
done
[ $NEXT_WAIT_TIME -lt 5 ]

echo 'Creating kafka topics'
while read topicName; do
  echo "Create topic ${topicName}."
  kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --create --if-not-exists --topic "${topicName}"
done <topics.list

echo 'Successfully created the following topics:'
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --list

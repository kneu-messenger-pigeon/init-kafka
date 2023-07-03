#!/usr/bin/env sh
# blocks until kafka is reachable
set -e

NEXT_WAIT_TIME=0
until [ $NEXT_WAIT_TIME -eq 5 ] || nc -z ${KAFKA_HOST//:/ }; do
  sleep $(( NEXT_WAIT_TIME++ ))
done

NEXT_WAIT_TIME=0
until [ $NEXT_WAIT_TIME -eq 5 ] || kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --list; do
    sleep $(( NEXT_WAIT_TIME++ ))
done
[ $NEXT_WAIT_TIME -lt 5 ]

echo 'Creating kafka topics'
while read topicName; do
  case $topicName in
  raw-scores)  PARTITIONS=2
  ;;
  scores-changes-feed)  PARTITIONS=6
  ;;
  *)  PARTITIONS=1
  ;;
  esac

  echo "Create topic ${topicName} with ${PARTITIONS} partitions."
  kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --create --if-not-exists --topic "${topicName}" --partitions ${PARTITIONS}
done <topics.list

echo 'Successfully created the following topics:'
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --list

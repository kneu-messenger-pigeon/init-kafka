#!/usr/bin/env sh
# blocks until kafka is reachable
set -e
NEXT_WAIT_TIME=0
until [ $NEXT_WAIT_TIME -eq 5 ] || kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --list; do
    sleep $(( NEXT_WAIT_TIME++ ))
done
[ $NEXT_WAIT_TIME -lt 5 ]

echo -e 'Creating kafka topics'
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --create --if-not-exists --topic meta_events --replication-factor 1 --partitions 1
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --create --if-not-exists --topic disciplines --replication-factor 1 --partitions 1
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --create --if-not-exists --topic raw_lessons --replication-factor 1 --partitions 1
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --create --if-not-exists --topic raw_scores --replication-factor 1 --partitions 2
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --create --if-not-exists --topic scores_changes_feed --replication-factor 1 --partitions 6
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --create --if-not-exists --topic authorized_users --replication-factor 1 --partitions 1

echo -e 'Successfully created the following topics:'
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --list

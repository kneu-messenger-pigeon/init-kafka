#!/usr/bin/env sh
# blocks until kafka is reachable
set -e
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --list

echo -e 'Creating kafka topics'
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --create --if-not-exists --topic metaevents --replication-factor 1 --partitions 1
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --create --if-not-exists --topic disciplines --replication-factor 1 --partitions 1
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --create --if-not-exists --topic raw_lessons --replication-factor 1 --partitions 3
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --create --if-not-exists --topic raw_scores --replication-factor 1 --partitions 5
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --create --if-not-exists --topic realtime_changes --replication-factor 1 --partitions 5
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --create --if-not-exists --topic scores_changes_feed --replication-factor 1 --partitions 5
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --create --if-not-exists --topic authorized_users --replication-factor 1 --partitions 1

echo -e 'Successfully created the following topics:'
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --list

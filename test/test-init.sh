#!/usr/bin/env bash
set -e

TEST_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
export TEST_DIR=$TEST_DIR

export KAFKA_TOPICS_LOG="$TEST_DIR/kafka-topics.sh-by-init.sh.log"

REAL_TIMEOUT=$(which timeout)
export REAL_TIMEOUT=$REAL_TIMEOUT

export TIMOUT_LOG="$TEST_DIR/timeout.log"
echo -n "" > "$TIMOUT_LOG"

export PATH="$TEST_DIR:$PATH"
echo "test1-topic" > topics.list
echo "test2-topic" >> topics.list
echo "scores-changes-feed" >> topics.list
echo "raw-scores" >> topics.list

## to pass tcp check - put google dns port
export KAFKA_HOST=8.8.8.8:53
export START_TIMEOUT=0
export FINISH_TIMEOUT=0
echo -n "" > "$KAFKA_TOPICS_LOG"

./init.sh
echo "init.sh exit code: $?"

grep " --create " "$KAFKA_TOPICS_LOG" | grep " --topic test1-topic " > /dev/null
grep " --create " "$KAFKA_TOPICS_LOG" | grep " --topic test2-topic " > /dev/null
grep " --create " "$KAFKA_TOPICS_LOG" | grep " --topic scores-changes-feed " | grep " --partitions 6 "  > /dev/null
grep " --create " "$KAFKA_TOPICS_LOG" | grep " --topic raw-scores " | grep " --partitions 2 "  > /dev/null

test -f healthcheck.sh
grep "kafka-topics.sh " healthcheck.sh | grep "test1-topic"  > /dev/null

echo "init.sh Test passed"

echo "Check healthcheck "

export KAFKA_TOPICS_LOG="$TEST_DIR/kafka-topics.sh-by-healthcheck.sh.log"
echo -n "" > "$KAFKA_TOPICS_LOG"

./healthcheck.sh
echo "healthcheck.sh exit code: $?"
grep " --describe  " "$KAFKA_TOPICS_LOG" | grep " --topic test1-topic " > /dev/null

echo "healthcheck.sh Test passed"



#!/usr/bin/env bash
set -e
# docker run -it -v `pwd`:/workspace -e KAFKA_HOST=127.0.0.1:9092 docker.io/bitnami/kafka:3.4-debian-11 /workspace/init.sh

# handle signals
trap "echo Exiting... INT;  exit $?" INT
trap "echo Exiting... TERM; exit $?" TERM
trap "echo Exiting... EXIT; exit $?" EXIT

# blocks until kafka is reachable
set -e
sleep "${START_TIMEOUT:-4}"
TCP_KAFKA_HOST=$(echo ${KAFKA_HOST} |  sed -e "s/:/\//")
NEXT_WAIT_TIME=0
until [ $NEXT_WAIT_TIME -eq 5 ] || timeout 1 bash -c "< /dev/tcp/${TCP_KAFKA_HOST}"; do
  sleep $NEXT_WAIT_TIME
  NEXT_WAIT_TIME=$((NEXT_WAIT_TIME+1))
done
[ $NEXT_WAIT_TIME -lt 5 ]

NEXT_WAIT_TIME=0
until [ $NEXT_WAIT_TIME -eq 5 ] || kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --list; do
  sleep $NEXT_WAIT_TIME
  NEXT_WAIT_TIME=$((NEXT_WAIT_TIME+1))
done
[ $NEXT_WAIT_TIME -lt 5 ]

echo 'Creating kafka topics'
date

cat topics.list | while read -r topicName; do
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
done

date
echo 'Successfully created the following topics:'
kafka-topics.sh --bootstrap-server "${KAFKA_HOST}" --list
date

echo "Create healthcheck script: ${CREATE_HEALTHCHECK_SCRIPT:=healthcheck.sh}"
mkdir -p $(dirname "$CREATE_HEALTHCHECK_SCRIPT")
FIRST_TOPIC=$(head -n 1 topics.list  | tr -d '\n')
echo "#!/usr/bin/env sh" > $CREATE_HEALTHCHECK_SCRIPT
echo "kafka-topics.sh --bootstrap-server localhost:9092 --topic \"$FIRST_TOPIC\" --describe" >> $CREATE_HEALTHCHECK_SCRIPT
chmod +x "${CREATE_HEALTHCHECK_SCRIPT}"

sleep "${FINISH_TIMEOUT:-0}"

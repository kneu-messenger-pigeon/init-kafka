[![Release](https://github.com/kneu-messenger-pigeon/init-kafka/actions/workflows/release.yaml/badge.svg)](https://github.com/kneu-messenger-pigeon/init-kafka/actions/workflows/release.yaml)
[![codecov](https://codecov.io/gh/kneu-messenger-pigeon/init-kafka/branch/main/graph/badge.svg?token=6MFQNOFBIT)](https://codecov.io/gh/kneu-messenger-pigeon/init-kafka)

### Run test kafka cluster

```shell
 docker run --rm -p 17092:9092 \
  -e KAFKA_ENABLE_KRAFT=yes \
  -e KAFKA_CFG_NODE_ID=1 \
  -e KAFKA_CFG_PROCESS_ROLES=broker,controller \
    -e KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER \
    -e KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093 \
    -e KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT \
    -e KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://127.0.0.1:9092 \
    -e KAFKA_BROKER_ID=1 \
    -e KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@127.0.0.1:9093 \
    -e ALLOW_PLAINTEXT_LISTENER=yes \
  --mount type=bind,source=./healthcheck.sh,target=/healthcheck.sh \
  --name test-kafka \
  bitnami/kafka:3.4-debian-11
```

FROM docker.io/bitnami/kafka:3.3

ENV KAFKA_HOST kafka:9092
ADD init.sh /init.sh
ENTRYPOINT /init.sh

package main

import (
	"errors"
	"fmt"
	"github.com/kneu-messenger-pigeon/events"
	"github.com/segmentio/kafka-go"
	"os"
	"time"
)

const healthCheckScript = `#!/usr/bin/env sh
kafka-topics.sh --bootstrap-server localhost:9092 --topic "%s" --describe`

var connectRetryInterval = time.Second * 2

func initKafka() error {
	startTimeout, _ := time.ParseDuration(os.Getenv("START_TIMEOUT"))
	fmt.Println("Start timeout: " + startTimeout.String())
	time.Sleep(startTimeout)

	kafkaHost := os.Getenv("KAFKA_HOST")
	fmt.Println("Kafka host: " + kafkaHost)

	healthCheckScriptPath := os.Getenv("CREATE_HEALTHCHECK_SCRIPT")
	fmt.Println("Healthcheck script path: " + healthCheckScriptPath)

	conn, err := waitStartKafka(kafkaHost)

	var partitions []kafka.Partition
	existsTopics := map[string]bool{}

	if err == nil {
		defer conn.Close()

		partitions, err = conn.ReadPartitions()
		for _, p := range partitions {
			existsTopics[p.Topic] = true
		}
	}

	if err == nil {
		createTopicsConfigs := make([]kafka.TopicConfig, 0, events.TopicsCount)
		for _, topicName := range events.GetTopics() {
			if existsTopics[topicName] {
				fmt.Println("Topic exist: " + topicName)

			} else {
				createTopicsConfigs = append(createTopicsConfigs, kafka.TopicConfig{
					Topic:             topicName,
					NumPartitions:     events.GetPartitionsByTopicName(topicName),
					ReplicationFactor: 1,
				})

				_, _ = fmt.Println("Create topic: " + topicName)
			}
		}

		if len(createTopicsConfigs) > 0 {
			err = conn.CreateTopics(createTopicsConfigs...)
			fmt.Printf("Create topics error: %v\n", err)
		}

		if err == nil {
			err = createHealthcheckScript(healthCheckScriptPath)
		}
	}

	finishTimeout, _ := time.ParseDuration(os.Getenv("FINISH_TIMEOUT"))
	fmt.Println("Finish timeout: " + finishTimeout.String())
	time.Sleep(finishTimeout)

	return err
}

func createHealthcheckScript(healthCheckScriptPath string) (err error) {
	if healthCheckScriptPath != "" {
		var healthCheckScriptFile *os.File
		healthCheckScriptFile, err = os.Create(healthCheckScriptPath)
		if err == nil {
			_, err = healthCheckScriptFile.WriteString(fmt.Sprintf(healthCheckScript, events.GetTopics()[0]))
			healthCheckScriptFile.Close()
			if err == nil {
				err = os.Chmod(healthCheckScriptPath, 0755)
			}
		}

		fmt.Fprintf(os.Stderr, "Create healthcheck script error: %v\n", err)
	}

	return
}

func waitStartKafka(kafkaHost string) (conn *kafka.Conn, err error) {
	for i := 1; i <= 10; i++ {
		conn, err = kafka.Dial("tcp", kafkaHost)
		if err != nil {
			fmt.Printf("kafka.Dial error: %v\n", err)
		}

		if err == nil {
			if _, err = conn.ApiVersions(); err != nil {
				fmt.Printf("apiVerions get error: %v\n", err)
			}
		}

		if err != nil && conn != nil {
			conn.Close()
			conn = nil
		}

		if conn != nil {
			return conn, nil
		}

		time.Sleep(connectRetryInterval)
	}

	return nil, errors.New("kafka is not available")
}

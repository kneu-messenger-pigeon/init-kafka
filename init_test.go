package main

import (
	"fmt"
	"github.com/kneu-messenger-pigeon/events"
	"github.com/stretchr/testify/assert"
	"log"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"
)

func TestInitKafka(t *testing.T) {
	t.Run("success", func(t *testing.T) {
		expectedHealthCheckScriptContent := `#!/usr/bin/env sh
kafka-topics.sh --bootstrap-server localhost:9092 --topic "meta-events" --describe`

		containerName := "test-kafka-success"
		healthCheckFilename := "tests/healthcheck.sh"
		port := "17092"

		cmd := exec.Command(
			"docker", "run", "--rm", "-d",
			"--name", containerName,
			"-p", port+":9092",
			"-e", "KAFKA_ENABLE_KRAFT=yes",
			"-e", "KAFKA_CFG_NODE_ID=1",
			"-e", "KAFKA_CFG_PROCESS_ROLES=broker,controller",
			"-e", "KAFKA_CFG_CONTROLLER_LISTENER_NAMES=CONTROLLER",
			"-e", "KAFKA_CFG_LISTENERS=PLAINTEXT://:9092,CONTROLLER://:9093",
			"-e", "KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT",
			"-e", "KAFKA_CFG_ADVERTISED_LISTENERS=PLAINTEXT://127.0.0.1:9092",
			"-e", "KAFKA_BROKER_ID=1",
			"-e", "KAFKA_CFG_CONTROLLER_QUORUM_VOTERS=1@127.0.0.1:9093",
			"-e", "ALLOW_PLAINTEXT_LISTENER=yes",
			"--mount", "type=bind,source=./tests/,target=/tests/",
			"bitnami/kafka:3.4-debian-11",
		)
		cmd.WaitDelay = time.Second * 3

		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		err := cmd.Run()
		if err != nil {
			log.Panic(err)
		}

		defer func() {
			cmd = exec.Command("docker", "rm", "-f", containerName)
			err = cmd.Run()
			if err != nil {
				log.Panic(err)
			}
		}()

		os.Setenv("KAFKA_HOST", "localhost:"+port)
		os.Setenv("CREATE_HEALTHCHECK_SCRIPT", healthCheckFilename)
		defer os.Unsetenv("KAFKA_HOST")
		defer os.Unsetenv("CREATE_HEALTHCHECK_SCRIPT")

		err = initKafka()

		assert.NoError(t, err)

		info, err := os.Stat(healthCheckFilename)
		assert.NoError(t, err)
		assert.Equal(t, info.Mode().String(), "-rwxr-xr-x")

		healthCheckFileContent, err := os.ReadFile(healthCheckFilename)
		assert.NoError(t, err)
		assert.Equal(t, expectedHealthCheckScriptContent, string(healthCheckFileContent))
		fmt.Println("success")

		cmd = exec.Command("docker", "exec", containerName, "/"+healthCheckFilename)
		err = cmd.Run()
		assert.NoError(t, err)

		cmd = exec.Command(
			"docker", "exec", containerName, "kafka-topics.sh",
			"--bootstrap-server", "localhost:9092", "--list",
		)
		outputBytes, err := cmd.Output()
		assert.NoError(t, err)

		existsTopics := strings.Split(
			strings.Trim(string(outputBytes), "\n"),
			"\n",
		)
		fmt.Println(existsTopics)

		assert.Equal(t, len(events.GetTopics()), len(existsTopics))
		for _, topicName := range events.GetTopics() {
			assert.Contains(t, existsTopics, topicName)
		}

		// run again to check that it doesn't fail
		err = initKafka()
		assert.NoError(t, err)
	})

	t.Run("kafka is not running", func(t *testing.T) {
		origStder := os.Stderr
		_, w, _ := os.Pipe()
		os.Stderr = w
		defer func() {
			os.Stderr = origStder
		}()

		origConnectRetryInterval := connectRetryInterval
		connectRetryInterval = time.Millisecond * 10
		defer func() {
			connectRetryInterval = origConnectRetryInterval
		}()

		os.Setenv("KAFKA_HOST", "localhost:33388")
		defer os.Unsetenv("KAFKA_HOST")

		err := initKafka()
		assert.Error(t, err)
	})
}

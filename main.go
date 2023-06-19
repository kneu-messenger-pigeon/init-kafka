package main

import (
	"fmt"
	"github.com/kneu-messenger-pigeon/events"
)

func main() {
	for _, topicName := range events.GetTopics() {
		fmt.Println(topicName)
	}
}

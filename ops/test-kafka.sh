#!/bin/bash

echo "=== Testing Kafka (KRaft Mode) ==="

# Test 1: Create a test topic
echo -e "\n[1] Creating topic 'factory.tasks'..."
docker exec agentic-init-kafka-1 kafka-topics.sh --create --topic factory.tasks --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1 2>/dev/null || echo "Topic may already exist"

# Test 2: List topics
echo -e "\n[2] Listing topics..."
docker exec agentic-init-kafka-1 kafka-topics.sh --list --bootstrap-server localhost:9092

# Test 3: Produce test message
echo -e "\n[3] Producing test message..."
echo "test-message-from-agentic-init" | docker exec -i agentic-init-kafka-1 kafka-console-producer.sh --topic factory.tasks --bootstrap-server localhost:9092

# Test 4: Consume test message
echo -e "\n[4] Consuming messages..."
docker exec agentic-init-kafka-1 kafka-console-consumer.sh --topic factory.tasks --from-beginning --bootstrap-server localhost:9092 --max-messages 1 --timeout-ms 5000

echo -e "\n=== Kafka Test Complete ==="
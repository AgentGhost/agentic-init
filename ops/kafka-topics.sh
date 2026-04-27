#!/bin/bash
# Create Kafka topics for Agentic Factory

KAFKA_CONTAINER="agentic-init-kafka-1"
KAFKA_BIN="/opt/kafka/bin/kafka-topics.sh"
BOOTSTRAP="localhost:9092"

echo "Creating Kafka topics..."

docker exec $KAFKA_CONTAINER bash -c "$KAFKA_BIN --create --topic agent-tasks --bootstrap-server $BOOTSTRAP --replication-factor 1 --partitions 3" 2>/dev/null || echo "agent-tasks may exist"

docker exec $KAFKA_CONTAINER bash -c "$KAFKA_BIN --create --topic agent-results --bootstrap-server $BOOTSTRAP --replication-factor 1 --partitions 3" 2>/dev/null || echo "agent-results may exist"

docker exec $KAFKA_CONTAINER bash -c "$KAFKA_BIN --create --topic task-lifecycle --bootstrap-server $BOOTSTRAP --replication-factor 1 --partitions 3" 2>/dev/null || echo "task-lifecycle may exist"

echo "Listing topics:"
docker exec $KAFKA_CONTAINER bash -c "$KAFKA_BIN --list --bootstrap-server $BOOTSTRAP"
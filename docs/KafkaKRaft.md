# Kafka / KRaft Mode

## Current Setup: Kafka 3.7.0 with KRaft

Starting from Kafka 3.7, **KRaft** (Kafka Raft) replaces Zookeeper for metadata management.

### Benefits

- No external Zookeeper required
- Self-contained Kafka cluster
- Simpler deployment
- Better scalability

### References

- [KIP-833: KRaft in open source](https://cwiki.apache.org/confluence.display/KAFKA/KIP-833%3A+KRaft+in+open+source)
- [Kafka without Zookeeper](https://developer.confluent.io/tutorials/set-up-self-managed-kafka/local)

### Docker Compose

Current kafka service (docker-compose.yml):
```yaml
kafka:
  image: apache/kafka:3.7.0
  # ...
```

No zookeeper service defined - using KRaft mode by default.

### Verification

```bash
# Check Kafka is running in KRaft mode
docker exec agentic-init-kafka-1 kafka-storage info
```

### Migration Notes

- Old setup: `Kafka + Zookeeper`
- New setup: `Kafka 3.7+` (KRaft, no Zookeeper)
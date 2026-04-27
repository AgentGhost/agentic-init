from kafka import KafkaProducer, KafkaConsumer
import time

print("=== Testing Kafka (KRaft Mode) ===\n")

# Test 1: Producer
print("[1] Testing Producer...")
try:
    producer = KafkaProducer(
        bootstrap_servers='localhost:9092',
        value_serializer=lambda v: v.encode('utf-8')
    )
    producer.send('factory.tasks', 'Test message from agentic-init')
    producer.flush()
    producer.close()
    print("    ✓ Producer working!")
except Exception as e:
    print(f"    ✗ Producer failed: {e}")

time.sleep(1)

# Test 2: Consumer
print("\n[2] Testing Consumer...")
try:
    consumer = KafkaConsumer(
        'factory.tasks',
        bootstrap_servers='localhost:9092',
        auto_offset_reset='earliest',
        consumer_timeout_ms=5000
    )
    messages = list(consumer)
    print(f"    ✓ Consumer working! Received {len(messages)} message(s)")
    for msg in messages:
        print(f"    → {msg.value.decode('utf-8')}")
    consumer.close()
except Exception as e:
    print(f"    ✗ Consumer failed: {e}")

print("\n=== Kafka Test Complete ===")
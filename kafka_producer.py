import json
import os
import time
from kafka import KafkaProducer, errors

KAFKA_TOPIC = "pcap-logs"
KAFKA_SERVER = "kafka:9092"
JSONL_FILE_PATH = "/pcap/output/parsed_logs.jsonl"

def create_producer():
    """Kafka Producer를 생성하고 연결을 시도합니다."""
    while True:
        try:
            producer = KafkaProducer(
                bootstrap_servers=KAFKA_SERVER,
                value_serializer=lambda v: json.dumps(v).encode('utf-8')
            )
            print("✅ Kafka Producer connected successfully.")
            return producer
        except errors.NoBrokersAvailable:
            print(f"❌ Failed to connect to Kafka brokers at {KAFKA_SERVER}. Retrying in 5 seconds...")
            time.sleep(5)

def stream_jsonl(producer, filepath):
    """jsonl 파일을 한 줄씩 읽어 Kafka 토픽으로 전송합니다."""
    print(f"🚀 Starting to stream data from '{filepath}'...")
    try:
        with open(filepath, 'r') as f:
            for line in f:
                try:
                    log_data = json.loads(line)
                    producer.send(KAFKA_TOPIC, value=log_data)
                except json.JSONDecodeError:
                    print(f"⚠️ Skipping malformed JSON line: {line.strip()}")
        producer.flush()
        print(f"✅ Finished streaming all data from '{filepath}'.")
    except FileNotFoundError:
        print(f"❌ File not found: {filepath}")
    except Exception as e:
        print(f"❌ An error occurred while streaming: {e}")

if __name__ == "__main__":
    print(f"⏳ Waiting for parser to create file: '{JSONL_FILE_PATH}'...")
    while not os.path.exists(JSONL_FILE_PATH):
        time.sleep(2)
    
    kafka_producer = create_producer()
    if kafka_producer:
        stream_jsonl(kafka_producer, JSONL_FILE_PATH)
        kafka_producer.close()


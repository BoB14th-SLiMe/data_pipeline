#!/bin/sh

# 무한 루프로 실시간 캡처 및 처리 실행
while true; do
    echo "------------------------------------------------------"
    echo "Starting new capture cycle at $(date)"
    
    # 1. Start tshark to capture packets for a given interval
    timeout ${INTERVAL} tshark -i eth0 -w /pcap/capture.pcap
    
    # 2. Parse the pcap file using the C++ parser
    # It reads /pcap/capture.pcap and creates /pcap/output/parsed_logs.jsonl
    /app/parser
    
    # 3. Stream the parsed jsonl data to Kafka
    if [ -f /pcap/output/parsed_logs.jsonl ]; then
        python3 /app/kafka_producer.py
        # 이전 파일을 삭제하여 다음 사이클 준비
        rm /pcap/output/parsed_logs.jsonl
    else
        echo "Parser did not create the output file. Skipping kafka stream."
    fi
    
    echo "Cycle finished. Waiting for next interval..."
    echo "------------------------------------------------------"
done


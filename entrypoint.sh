#!/bin/sh

# 무한 루프로 실시간 캡처 및 처리 실행
while true; do
    echo "------------------------------------------------------"
    echo "Starting new capture cycle at $(date)"
    
    # 1. tshark를 시작하여 주어진 시간 간격 동안 패킷 캡처
    # (INTERVAL 환경 변수가 없으면 기본값 30초 사용)
    timeout ${INTERVAL:-30} tshark -i eth0 -w /pcap/capture.pcap
    
    # 2. C++ 파서를 사용하여 pcap 파일 분석
    # /pcap/capture.pcap 파일을 읽어 /pcap/output/parsed_logs.jsonl 생성
    ./pcap_parser
    
    # 3. 분석된 jsonl 데이터를 Kafka로 스트리밍
    if [ -f /pcap/output/parsed_logs.jsonl ]; then
        python3 ./kafka_producer.py
        # 다음 사이클을 위해 이전 파일 삭제
        rm /pcap/output/parsed_logs.jsonl
    else
        echo "Parser did not create the output file. Skipping kafka stream."
    fi
    
    echo "Cycle finished. Waiting for next interval..."
    echo "------------------------------------------------------"
done


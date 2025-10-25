#!/bin/sh

# 무한 루프로 실시간 캡처 및 처리 실행
while true; do
    echo "------------------------------------------------------"
    echo "Starting new capture cycle at $(date)"
    
    # 1. tshark를 시작하여 주어진 시간 간격 동안 패킷 캡처
    # (INTERVAL 환경 변수가 없으면 기본값 30초 사용)
    timeout ${INTERVAL:-30} tshark -i eth0 -w /pcap/capture.pcap
    
    # 2. C++ 파서를 사용하여 pcap 파일 분석
    # 이 스크립트는 Dockerfile에 의해 현재 아키텍처에 맞는 pcap_parser가 준비되었다고 가정합니다.
    ./pcap_parser
    
    # 3. 분석된 jsonl 데이터를 Kafka로 스트리밍
    # ✨ 수정된 부분: 파일이 존재하고, 내용이 비어있지 않은지 함께 확인합니다.
    if [ -f /pcap/output/parsed_logs.jsonl ] && [ -s /pcap/output/parsed_logs.jsonl ]; then
        python3 ./kafka_producer.py
        # 다음 사이클을 위해 이전 파일 삭제
        rm /pcap/output/parsed_logs.jsonl
    else
        echo "Parser did not create the output file or the file is empty. Skipping kafka stream."
    fi
    
    echo "Cycle finished. Waiting for next interval..."
    echo "------------------------------------------------------"
done


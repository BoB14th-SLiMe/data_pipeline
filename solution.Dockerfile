# 베이스 이미지
FROM python:3.12-slim

# C++ 빌드 도구, cmake, tshark/pcap 등 설치
RUN apt-get update && apt-get install -y \
    build-essential cmake \
    tshark libpcap-dev ca-certificates tzdata procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# C++ 바이너리 파일 복사
COPY ./pcap_parser /app/pcap_parser

# 컴파일된 바이너리를 실행 경로로 복사 (실행 파일 이름을 pcap_parser로 변경)
RUN cp /app/pcap_parser /usr/local/bin/pcap_parser

# 원래 작업 디렉토리로 복귀
WORKDIR /app

# 파이썬 의존성
COPY settings/solution/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r /app/requirements.txt

# 스크립트 복사
COPY settings/solution/entrypoint.sh /app/entrypoint.sh
COPY settings/solution/json2csv_parser.py /app/json2csv_parser.py
COPY settings/solution/kafka_producer.py /app/kafka_producer.py
RUN apt-get update && apt-get install -y dos2unix && \
    dos2unix /app/entrypoint.sh && \
    chmod 755 /app/entrypoint.sh

ENTRYPOINT ["/bin/bash", "/app/entrypoint.sh"]
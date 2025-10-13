# --- STAGE 1: Builder Stage ---
# 이 단계에서는 빌드에 필요한 모든 도구를 설치합니다. (변경 없음)
FROM python:3.12-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    tshark \
    libpcap-dev \
    ca-certificates \
    tzdata \
    procps \
    dos2unix \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY . .


# --- STAGE 2: Final Stage (Optimized) ---
# 이 단계에서는 실제 실행에 필요한 파일만으로 가벼운 최종 이미지를 만듭니다.
FROM python:3.12-slim

WORKDIR /app

# Builder 스테이지에서 필요한 모든 파일을 한 번에 복사합니다.
COPY --from=builder /build/requirements.txt \
    /build/pcap_parser \
    /build/entrypoint.sh \
    /build/kafka_producer.py \
    /build/json2csv_parser.py \
    ./

# 패키지 설치, 파이썬 의존성 설치, 권한 부여, 불필요한 파일 정리를 하나의 레이어로 실행합니다.
RUN apt-get update && apt-get install -y --no-install-recommends \
        tshark \
        libpcap-dev \
        ca-certificates \
        tzdata \
        procps \
        dos2unix \
    && pip install --no-cache-dir -r requirements.txt \
    && chmod +x ./pcap_parser ./entrypoint.sh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 컨테이너 시작점 설정
ENTRYPOINT ["./entrypoint.sh"]


# =================================================================
# STAGE 1: C++ Parser Builder
# 이 단계에서는 각 아키텍처(amd64, arm64)에 맞는 C++ 파서를 컴파일합니다.
# =================================================================
FROM ubuntu:22.04 AS parser_builder

# 빌드에 필요한 도구 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    libpcap-dev

# C++ 소스 코드를 컨테이너 안으로 복사
WORKDIR /src
COPY TCP_Datagram_parser .

# Release 모드로 최적화하여 컴파일
# buildx가 플랫폼에 맞는 컴파일을 자동으로 수행합니다.
RUN cmake -B build -DCMAKE_BUILD_TYPE=Release
RUN cmake --build build

# =================================================================
# STAGE 2: Final Application Image
# 실제 프로그램을 실행하는 최종 이미지를 만듭니다.
# =================================================================
FROM python:3.12-slim

WORKDIR /app

# 필요한 시스템 패키지를 설치합니다.
RUN apt-get update && apt-get install -y --no-install-recommends \
        tshark \
        libpcap0.8 \
        ca-certificates \
        tzdata \
    && rm -rf /var/lib/apt/lists/*

# 파이썬 관련 파일들을 복사합니다.
COPY . .

# ✨ 핵심: STAGE 1에서 아키텍처에 맞게 컴파일된 parser 실행 파일만 복사합니다.
COPY --from=parser_builder /src/build/parser /app/pcap_parser

# 파이썬 의존성을 설치하고 실행 권한을 부여합니다.
RUN pip install --no-cache-dir -r requirements.txt \
    && chmod +x ./pcap_parser ./entrypoint.sh

# 컨테이너 시작점 설정
ENTRYPOINT ["/app/entrypoint.sh"]
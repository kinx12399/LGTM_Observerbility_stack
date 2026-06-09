# LGTM Observability Stack

LGTM Observability Stack은 Grafana 기반 모니터링, 로그, 트레이스 통합 관찰성 환경을 Docker Compose로 구성한 프로젝트입니다.

## 1. 아키텍처

```
====================================== [ VM 서버 환경 ] ======================================
  
         (로그 소스)                                (메트릭 소스)             (트레이스 소스)
  +----------------------+                     +-----------------+   +---------------------+
  | /var/log/syslog 등   |                     | /proc, /sys 등   |   |  App / Infra 데몬   |
  | 시스템/도커 로그       |                     |  하드웨어 자원     |  |      요청 발생      |
  +----------+-----------+                     +--------+--------+   +----------+----------+
             | (실시간 감시)                              |                      |
             v                                          v                       |
  +----------------------+                     +-----------------+              |
  |       Promtail       |                     |  Node Exporter  |              |
  |      로그 에이전트     |                     |   메트릭 생성기   |              |
  +----------+-----------+                     +--------+--------+              |
             |                                          |  15초 주기             |
             |                                          | Pull / Scrape         |
             |                                          v                       |
             |                                 +-----------------+              |
             |                                 |   Prometheus    |              |
             |                                 |   메트릭 배달부   |              |
             |                                 +--------+--------+              |
             |                                          |                       |
             | Push (HTTP)                              | Remote Write          | gRPC (Port 4317)
             |                                          |                       |
             |                                          v                       v
=============|==========================================|=======================|==============
             |                                          |                       |
             |                                          |                       |
             v                                          v                       v
  +----------------------+                     +-----------------+    +------------------+
  |         Loki         |                     |      Mimir      |    |      Tempo       |
  |                      |                     |                 |    |                  |
  |    (초경량 로그 DB)    |                     | (메트릭 장기DB)  |    | (트레이스 추적 DB) |
  |                      |                     | [Ruler 엔진내장] |    |                  |
  +----------+-----------+                     +--------+--------+    +---------+--------+
             |                                          |                       |
             |                                          +-----------+-----------+
             |                                                      | S3 API 기반
             |                                                      | Read / Write
             |                                                      v
             |                                           +---------------------+
             |                                           |        MinIO        |
             |                                           | (로컬 S3 스토리지)    |
             |                                           | [mimir / tempo-data]|
             |                                           +---------------------+
             |                                                      |
             |                  Query (LogQL / PromQL / TraceID)    |
             +----------------------------+   +---------------------+
                                          |   |
                                          v   v
                               +-------------------------+
                               |         Grafana         |
                               |    (통합 시각화 웹 UI)  |
                               +------------+------------+
                                            |
                                            | (임계치 초과 / 발송 테스트)
                                            v
                               +-------------------------+
                               |     네이버 SMTP 메일      |
                               |     (이메일 알람 수신)     |
                               +-------------------------+

============================================================================================
```

- 모든 서비스는 `lgtm-net` 브리지 네트워크로 연결됩니다.
- Prometheus는 메트릭을 `Mimir`로 `remote_write` 합니다.
- Loki는 Promtail이 수집한 로그를 저장합니다.
- Tempo는 OTLP gRPC 트레이스를 수집하고 MinIO에 저장합니다.

## 2. 사전 요구사항

- Ubuntu VM 환경
- Docker 버전: `Docker version 29.5.3, build d1c06ef`
- Docker Compose 버전: `Docker Compose version v5.1.4`
- 설치에 필요한 도구: `git`, `curl`, `wget`

## 3. 설치 및 기동 방법

```bash
sudo apt update
sudo apt upgrade -y

sudo apt install -y git curl wget

# 1. Docker 자동 설치 스크립트 다운로드 및 실행
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 2. 현재 사용자(ubuntu)를 docker 그룹에 추가하여 sudo 없이 명령이 가능하도록 설정
sudo usermod -aG docker $USER
newgrp docker

# 3. 설치 완료된 Docker 및 Compose 버전 확인 (검증용)
docker --version
docker compose version

# 4. 사용이 끝난 가설치 스크립트 파일 삭제
rm get-docker.sh

git clone https://github.com/kinx12399/LGTM_Observerbility_stack.git
cd LGTM_Observerbility_stack/

docker compose up -d

# 5. Mimir, Prometheus, MinIO를 포함한 모든 컨테이너가 정상 구동(Up/Healthy) 중인지 로그 확인
docker compose logs --tail=20 mimir
docker compose logs --tail=20 prometheus
```

## 4. 각 서비스 접속 URL 및 계정 정보

- Grafana: `http://1.201.177.179:3000`
  - ID: `admin`
  - PW: 문의해주시면 감사하겠습니다.
- Prometheus: 내부 서비스 `http://prometheus:9090`
- Loki: 내부 서비스 `http://loki:3100`
- Tempo: 내부 서비스 `http://tempo:3200` (OTLP gRPC: `4317`)
- Mimir: 내부 서비스 `http://mimir:9009`
- MinIO: 내부 서비스 `http://minio:9000`
  - Access Key: `mimir`
  - Secret Key: `supersecret`
- Node Exporter: 내부 서비스 `http://node-exporter:9100`

> 참고: `prometheus`, `loki`, `tempo`, `mimir`, `minio`, `node-exporter`는 외부 호스트 포트가 직접 매핑되어 있지 않으므로 Docker 네트워크 내부에서 접근하거나 필요한 경우 포트 포워딩/호스트 포트 매핑을 추가해야 합니다.

## 5. 주요 설정 설명

### config/prometheus.yml
- `global.scrape_interval`: Prometheus가 메트릭을 15초 간격으로 수집하도록 설정합니다.
- `remote_write`: 수집한 메트릭을 `http://mimir:9009/api/v1/push`로 전송합니다.
- `scrape_configs`: Prometheus 자체와 `node-exporter`의 메트릭을 스크랩하도록 구성합니다.

### config/loki-config.yaml
- `auth_enabled: false`: 인증 없이 로그 수집을 허용합니다.
- `server.http_listen_port`: Loki HTTP API 포트 `3100`.
- `common.storage.filesystem`: 로그 청크 및 룰을 로컬 파일 시스템에 저장합니다.
- `schema_config`: TSDB 스토리지와 24시간 인덱스 주기, `v13` 스키마를 사용합니다.
- `limits_config.retention_period: 168h`: 로그 보관 기간을 7일로 제한합니다.
- `compactor.retention_enabled: true`: 보관 기간을 실제로 적용하는 compactor를 활성화합니다.

### config/promtail-config.yaml
- `server.http_listen_port: 9080`: Promtail 관리 API 포트.
- `positions.filename`: 마지막으로 처리한 로그 위치를 저장합니다.
- `clients.url`: Loki `http://loki:3100/loki/api/v1/push`로 로그 전송.
- `scrape_configs`: `/var/log/*log` 경로의 시스템 로그를 `job: varlogs` 레이블로 수집합니다.

### config/tempo-config.yaml
- `server.http_listen_port: 3200`: Tempo HTTP API 포트.
- `multitenancy_enabled: false`: 단일 테넌트 모드로 설정하여 org id 관련 인증 문제를 회피합니다.
- `distributor.receivers.otlp.protocols.grpc.endpoint: 0.0.0.0:4317`: OTLP gRPC 수신 포트.
- `storage.trace.backend: s3`: 트레이스 데이터를 MinIO S3 호환 스토리지에 저장합니다.
- `storage.trace.s3`: MinIO 엔드포인트, 인증 정보, 버킷 `tempo-data`를 사용합니다.
- `wal.path`: write-ahead log 저장 위치를 `/var/tempo/wal`로 설정합니다.

### config/mimir-config.yaml
- `target: all`: Mimir를 모놀리식 단일 바이너리로 실행합니다.
- `multitenancy_enabled: false`: 단일 테넌트 환경으로 구성합니다.
- `server.http_listen_port: 9009`: Mimir HTTP API 포트.
- `blocks_storage.backend: s3`: 블록 스토리지를 MinIO S3로 설정합니다.
- `s3.bucket_name: mimir`: Mimir 블록 스토리지 버킷.
- `tsdb.dir`: 로컬 TSDB 저장 경로를 `/data/tsdb`로 지정합니다.
- `ingester.ring.replication_factor: 1`: 단일 복제 인스턴스 구성.
- `compactor.data_dir`: 컴팩터 상태 저장 디렉터리를 `/data/compactor`로 설정합니다.

## 6. 트러블슈팅 기록

### 1) `err="server returned HTTP status 401 Unauthorized: no org id\n"`
- 원인: Tempo/Mimir 기본 설정이 멀티테넌시를 전제로 하여 조직 ID(org id) 확인을 요구했습니다.
- 조치: `multitenancy_enabled: false`를 `config/tempo-config.yaml`과 `config/mimir-config.yaml`에 추가하여 단일 테넌트 모드로 전환했습니다.
- 결과: org id 헤더가 없는 로컬 관찰성 스택에서 인증 오류 없이 정상 연결되었습니다.

### 2) MinIO가 준비되지 않은 상태에서 종속 컨테이너가 시작됨
- 원인: `create-bucket`, `mimir`, `tempo`가 MinIO 컨테이너가 완전히 준비되기 전에 연결을 시도하여 초기화 실패가 발생했습니다.
- 조치: MinIO 서비스에 다음 healthcheck를 추가했습니다.
  - `curl -f http://localhost:9000/minio/health/live`
  - `interval: 5s`, `timeout: 5s`, `retries: 5`
- 조치: `create-bucket`, `mimir`, `tempo` 컨테이너에 `depends_on: minio: condition: service_healthy`를 추가했습니다.
- 결과: MinIO가 헬스체크를 통과한 이후에 종속 서비스가 시작되므로 버킷 생성 및 연결 안정성이 확보되었습니다.


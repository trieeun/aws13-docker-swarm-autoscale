# Grafana 대시보드 설계

## 패널 1 — 컨테이너별 CPU 사용률

- 제목: Container CPU Usage (%)
- 시각화 타입: Time series (선 그래프)
- PromQL:
  rate(container_cpu_usage_seconds_total{
    name=~"web_nginx.*",
    container!=""
  }[1m]) * 100

- Y축 단위: percent (0~100)
- 임계선: 40% (빨간 점선) ← Alert 기준


## 패널 2 — 컨테이너 메모리 사용률

- 제목: Container Memory Usage (%)
- 시각화 타입: Gauge (게이지)
- PromQL:
  container_memory_usage_bytes{name=~"web_nginx.*"}
  /
  container_spec_memory_limit_bytes{name=~"web_nginx.*"}
  * 100

- 단위: percent
- 임계선: 70% (빨간색)


## 패널 3 — 실행 중인 컨테이너 수 (Scale 추적)

- 제목: Running Nginx Containers
- 시각화 타입: Stat (숫자 크게 표시)
- PromQL:
  count(container_last_seen{name=~"web_nginx.*"})

- 이 패널로 Auto Scaling이 일어날 때
  숫자가 2→3→4로 변하는 것을 추적함


## 패널 4 — 네트워크 In/Out

- 제목: Network Traffic (bytes/s)
- 시각화 타입: Time series
- PromQL (수신):
  rate(container_network_receive_bytes_total{
    name=~"web_nginx.*"
  }[1m])

- PromQL (송신):
  rate(container_network_transmit_bytes_total{
    name=~"web_nginx.*"
  }[1m])

- 단위: bytes/sec

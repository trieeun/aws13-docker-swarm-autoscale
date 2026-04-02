# Grafana Alert 규칙 정의

## Alert 1 — CPU 과부하 경고

| 항목 | 값 |
|---|---|
| 이름 | High CPU Usage |
| 조건 | CPU 사용률 > 40% |
| 지속 시간 | 5초 이상 유지 시 발동 |
| 심각도 | critical |
| 알림 채널 | Slack #grafana-alert |
| 메시지 | "⚠️ CPU 사용률이 40%를 초과했습니다. 현재: {{ $value }}%" |

PromQL:
  rate(container_cpu_usage_seconds_total{
    name=~"web_nginx.*"
  }[1m]) * 100 > 40


## Alert 2 — 메모리 과부하 경고

| 항목 | 값 |
|---|---|
| 이름 | High Memory Usage |
| 조건 | Memory 사용률 > 70% |
| 지속 시간 | 10초 이상 유지 시 발동 |
| 심각도 | warning |
| 알림 채널 | Slack #grafana-alert |
| 메시지 | "⚠️ 메모리 사용률이 70%를 초과했습니다. 현재: {{ $value }}%" |


## Alert 상태 전환 흐름

  Normal → Pending (조건 충족했지만 지속시간 미달)
         → Firing  (조건 + 지속시간 모두 충족 → Slack 발송)
         → Resolved (조건 해소 → Slack에 해소 메시지 발송)


## 테스트 방법 (Day 3에 진행)

  Worker 노드에서 stress 실행:
  stress --cpu 2 --timeout 60s

  확인 순서:
  1. Grafana에서 Pending 상태 진입 확인
  2. 5초 후 Firing으로 전환 확인
  3. Slack 알람 수신 확인
  4. stress 종료 후 Resolved 메시지 확인

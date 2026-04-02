#!/bin/bash

# ════════════════════════════════════════
#   Docker Swarm Auto Scaler (개선판)
#   대상 서비스: web_nginx
# ════════════════════════════════════════

# ─── 상수 정의 ───────────────────────────
SERVICE_NAME="web_nginx"
MAX_CONTAINERS=6          # t3.micro 3대 기준 (노드당 2개)
MIN_CONTAINERS=2          # 최소 유지 컨테이너 수
SCALE_OUT_CPU=50          # Scale Out 기준 CPU (%)
SCALE_IN_CPU=20           # Scale In  기준 CPU (%)
CHECK_INTERVAL=10         # 체크 주기 (초)
SCALE_IN_COOLDOWN=30      # Scale In 쿨다운 (초) ← 연속 Scale In 방지
LOG_FILE="/var/log/autoscale.log"

# ─── 로그 함수 ───────────────────────────
log() {
  local TIMESTAMP
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

# ─── 초기화 ──────────────────────────────
LAST_SCALE_IN_TIME=0   # 마지막 Scale In 시각 (epoch seconds)

log "====== AutoScaler 시작 ======"
log "설정: MAX=$MAX_CONTAINERS, MIN=$MIN_CONTAINERS, OUT_CPU=${SCALE_OUT_CPU}%, IN_CPU=${SCALE_IN_CPU}%"

# ─── 메인 루프 ───────────────────────────
while true; do

  # 1. CPU 사용률 측정
  cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}')
  used_cpu=$(echo "100 - $cpu_idle" | bc)
  rounded_used_cpu=$(printf "%.0f" $used_cpu)

  # 2. 현재 실행 중인 컨테이너 수 측정
  tot=$(docker service ls \
        --filter name="$SERVICE_NAME" \
        --format "{{.Replicas}}" | cut -d'/' -f1)

  log "상태 확인 → CPU: ${rounded_used_cpu}% | 컨테이너: ${tot}개"

  # 3. Scale Out 조건
  if [ "$rounded_used_cpu" -gt "$SCALE_OUT_CPU" ] && \
     [ "$tot" -lt "$MAX_CONTAINERS" ]; then

    NEW_COUNT=$(($tot + 1))
    log "▲ SCALE OUT: ${tot} → ${NEW_COUNT} | CPU ${rounded_used_cpu}% > ${SCALE_OUT_CPU}%"
    docker service scale "${SERVICE_NAME}=${NEW_COUNT}"

  # 4. Scale In 조건 (쿨다운 포함)
  elif [ "$rounded_used_cpu" -lt "$SCALE_IN_CPU" ] && \
       [ "$tot" -gt "$MIN_CONTAINERS" ]; then

    NOW=$(date +%s)
    ELAPSED=$(($NOW - $LAST_SCALE_IN_TIME))

    # 쿨다운 시간이 지났을 때만 Scale In 실행
    if [ "$ELAPSED" -gt "$SCALE_IN_COOLDOWN" ]; then
      NEW_COUNT=$(($tot - 1))
      log "▼ SCALE IN:  ${tot} → ${NEW_COUNT} | CPU ${rounded_used_cpu}% < ${SCALE_IN_CPU}%"
      docker service scale "${SERVICE_NAME}=${NEW_COUNT}"
      LAST_SCALE_IN_TIME=$NOW
    else
      WAIT=$(($SCALE_IN_COOLDOWN - $ELAPSED))
      log "⏳ Scale In 쿨다운 대기 중... (${WAIT}초 남음)"
    fi

  else
    # Scale 없음 (정상 상태)
    :
  fi

  sleep "$CHECK_INTERVAL"

done

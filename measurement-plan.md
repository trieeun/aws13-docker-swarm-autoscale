# Auto Scaling 반응 시간 측정 계획

## 측정 목표
Shell 기반 Auto Scaling과 CloudWatch 기반 Auto Scaling의
반응 시간을 동일 조건 10회 실험으로 정량 비교한다.

## 측정 항목
- 반응 시간: stress 명령 실행 시각 ~ 컨테이너 수 증가 감지 시각

## 공통 실험 조건
- 시작 상태: Nginx 컨테이너 2개
- 부하 명령: stress --cpu 2 --timeout 120s
- 실행 노드: Worker 1
- 반복 횟수: 10회

## Shell 방식 측정 절차

  1. 컨테이너 2개 상태 확인
     docker service ls

  2. stress 실행 + 시작 시각 기록
     START=$(date +%s%N)
     stress --cpu 2 --timeout 120s &

  3. 컨테이너 증가 감지 (별도 터미널에서)
     watch -n 1 docker service ps web_nginx

  4. 3번째 컨테이너 생성되는 순간 시각 기록
     END=$(date +%s%N)

  5. 반응 시간 계산 (나노초 → 초)
     echo "scale=2; ($END - $START) / 1000000000" | bc


## CloudWatch 방식 측정 절차

  1. CloudWatch Alarm 설정
     - 지표: SwarmProject/cpu_usage_active
     - 조건: >= 50% 가 1분 동안 지속
     - 액션: SNS → Lambda or EC2 Auto Scaling

  2. 동일하게 stress 실행 + 시작 시각 기록

  3. CloudWatch Alarm 상태가 ALARM으로 바뀌는 시각 기록
     (CloudWatch 콘솔에서 확인)

  4. 반응 시간 계산


## 결과 기록표

| 회차 | Shell 방식(초) | CloudWatch 방식(초) |
|:----:|:-------------:|:------------------:|
|  1   |               |                    |
|  2   |               |                    |
|  3   |               |                    |
|  4   |               |                    |
|  5   |               |                    |
|  6   |               |                    |
|  7   |               |                    |
|  8   |               |                    |
|  9   |               |                    |
| 10   |               |                    |
| **평균** |           |                    |

## 예상 결과
- Shell 방식: 평균 5~15초 (스크립트 check_interval에 의존)
- CloudWatch 방식: 평균 60~120초 (CloudWatch 최소 수집 주기 1분)

## 결론 포인트 (면접용)
빠른 반응이 필요한 환경 → Shell 방식
AWS 네이티브 통합, 비용/관리 효율 → CloudWatch 방식

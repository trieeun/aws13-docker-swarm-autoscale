#!/bin/bash

# ─── CloudWatch Agent 설치 스크립트 ───

echo "[1/4] CloudWatch Agent 패키지 다운로드..."
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

echo "[2/4] 패키지 설치..."
sudo dpkg -i amazon-cloudwatch-agent.deb

echo "[3/4] 설정 파일 생성..."
sudo tee /opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json > /dev/null <<'EOF'
{
  "metrics": {
    "namespace": "SwarmProject",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_active"],
        "metrics_collection_interval": 10
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 10
      }
    },
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}",
      "NodeType": "worker"
    }
  }
}
EOF

echo "[4/4] CloudWatch Agent 시작..."
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-config.json \
  -s

echo "✅ CloudWatch Agent 설치 완료"
echo "CloudWatch 콘솔 → 지표 → SwarmProject 에서 확인하세요"

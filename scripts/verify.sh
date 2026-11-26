#!/usr/bin/env bash
# ============================================================================
# 验证容器观测采集器是否就绪
# ============================================================================
# 用法：./verify.sh
# 检查项：
#   1. 所有采集器 Pod 处于 Running / Ready
#   2. node-exporter 暴露 /metrics（经 node IP 或本地端口 9100）
#   3. Prometheus 已抓取目标（可选，本脚本只验证 Pod 与端口）
#
# 前置：kubectl 已配置连接 CCE 集群。

set -euo pipefail

echo "=== 1. 采集器 Pod 状态 ==="
kubectl get pods -n observability -o wide

echo
echo "=== 2. DaemonSet / Deployment 状态 ==="
kubectl get daemonset,deployment -n observability

echo
echo "=== 3. node-exporter /metrics 端点（任一节点）==="
NODE_IP=$(kubectl get nodes -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
echo "节点 IP: ${NODE_IP}"
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
  ip=$(kubectl get node "$node" -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
  code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://${ip}:9100/metrics" || echo 000)
  echo "  ${node} (${ip}:9100) -> HTTP ${code}"
done

echo
echo "=== 4. Prometheus 服务端点 ==="
kubectl get svc prometheus -n observability

echo
echo "=== 5. Fluent-Bit 日志采集（最近日志）==="
kubectl logs -n observability -l k8s-app=fluent-bit --tail=3 2>/dev/null || \
    kubectl logs -n observability -l k8s-app=fluent-bit -c fluent-bit --tail=3

echo
echo "验证完成。指标可视化可导入 dashboards/*.json 到 Grafana（详见部署指导书）。"
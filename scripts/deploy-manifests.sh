#!/usr/bin/env bash
# ============================================================================
# 部署容器观测采集器到 CCE 集群
# ============================================================================
# 用法：
#   ./deploy-manifests.sh               # 部署全部采集器清单（namespace/SA/指标/日志）
#   ./deploy-manifests.sh --quickstart  # 部署一键组合清单
#   ./deploy-manifests.sh --redis       # 额外部署示例流量（Redis + exporter）
#   ./deploy-manifests.sh --clean       # 清理全部采集器
#
# 前置：kubectl 已配置连接 CCE 集群（获取 kubeconfig 见 README / 部署指导书）。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS_DIR="${SCRIPT_DIR}/../src/manifests"

usage() {
    grep '^#' "$0" | sed 's/^# \{0,1\}//'
    exit 0
}

CMD="${1:-default}"

case "$CMD" in
    -h|--help)
        usage
        ;;
    --quickstart)
        echo "[*] 部署一键组合清单 ..."
        kubectl apply -f "${MANIFESTS_DIR}/quickstart/quickstart-all-in-one.yaml"
        ;;
    --redis)
        echo "[*] 部署示例流量（Redis + exporter）..."
        kubectl apply -f "${MANIFESTS_DIR}/00-namespace.yaml" \
                      -f "${MANIFESTS_DIR}/sample-traffic/redis-demo.yaml"
        ;;
    --clean)
        echo "[*] 清理全部采集器（保留命名空间与示例可另行删除）..."
        kubectl delete -f "${MANIFESTS_DIR}/quickstart/quickstart-all-in-one.yaml" --ignore-not-found
        kubectl delete -f "${MANIFESTS_DIR}/sample-traffic/redis-demo.yaml" --ignore-not-found
        ;;
    default)
        echo "[*] 创建命名空间与 RBAC ..."
        kubectl apply -f "${MANIFESTS_DIR}/00-namespace.yaml" \
                      -f "${MANIFESTS_DIR}/01-serviceaccount.yaml"
        echo "[*] 部署节点指标采集（node-exporter DaemonSet）..."
        kubectl apply -f "${MANIFESTS_DIR}/metrics/node-exporter-daemonset.yaml"
        echo "[*] 部署集群对象指标采集（kube-state-metrics）..."
        kubectl apply -f "${MANIFESTS_DIR}/metrics/kube-state-metrics-deployment.yaml"
        echo "[*] 部署 Prometheus 指标汇聚 ..."
        kubectl apply -f "${MANIFESTS_DIR}/metrics/prometheus-service.yaml"
        echo "[*] 部署日志采集（Fluent-Bit DaemonSet）..."
        kubectl apply -f "${MANIFESTS_DIR}/logs/fluent-bit-daemonset.yaml"
        echo "[*] 完成。查看资源状态："
        kubectl get pods -n observability
        ;;
esac
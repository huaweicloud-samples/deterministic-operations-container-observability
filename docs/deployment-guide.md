# 部署指导书

本指导书带你从零部署「容器可观测性采集链路」到华为云云容器引擎（CCE），并用预置仪表盘查看指标。

## 1. 前置准备

| 项 | 要求 | 说明 |
|---|---|---|
| 账号 | 已实名认证的华为云账号 | 个人 / 企业均可 |
| 权限 | IAM 具备 VPC / CCE / LTS / SWR 相关权限 | 建议 Tenant Administrator 或等效 |
| 工具 | Terraform ≥ 1.5、Python ≥ 3.10 + kubernetes 库 | 部署与验证 |
| 密钥对 | ECS 控制台已创建 SSH 密钥对 | CCE 节点登录用，部署时填名称 |
| AK/SK | 华为云「我的凭证」页面获取 | 用于 terraform provider 与 SWR 镜像推送，勿写入代码库 |

## 2. 创建基础设施

```bash
cd infra
cp terraform.tfvars.example terraform.tfvars
# 编辑 terraform.tfvars：填入 region / project_name / node_keypair_name 等

export HW_ACCESS_KEY="<AK>"
export HW_SECRET_KEY="<SK>"

terraform init
terraform plan
terraform apply -auto-approve
```

**预期**：创建 VPC、CCE 集群、节点池、SWR 组织、LTS 日志组与日志流；outputs 输出集群端点、LTS 资源名等。

## 3. 连接集群

获取集群证书后通过 Python kubernetes 客户端或 kubectl 连接：

```bash
# 方式一：通过 Terraform state 获取集群证书
terraform state show huaweicloud_cce_cluster.main
# 提取 certificate_authority_data / client_certificate_data / client_key_data
# Base64 解码后写入临时文件，配置 kubernetes 客户端

# 方式二：控制台 CCE → 集群 → 连接信息 → kubectl 下载
kubectl --kubeconfig=<path-to-kubeconfig> get nodes
```

**验证**：`kubectl get nodes` 输出 Ready 节点。

## 4. 镜像准备（SWR）

CCE 节点默认无法访问 Docker Hub / registry.k8s.io / quay.io 等外部镜像仓库。需要将镜像推送到 SWR 私有仓库：

```bash
# 获取 SWR 登录凭证
hcloud SWR CreateAuthorizationToken --cli-region=<region> --namespace=<swr-namespace>

# 使用 skopeo 复制镜像到 SWR（以 node-exporter 为例）
skopeo copy --override-arch arm64 \
  docker://quay.io/prometheus/node-exporter:v1.8.2 \
  docker://swr.<region>.myhuaweicloud.com/<namespace>/node-exporter:v1.8.2 \
  --dest-creds="<username>:<password>"

# 创建 Kubernetes image pull secret
kubectl create secret docker-registry swr-pull-secret \
  --namespace=observability \
  --docker-server=swr.<region>.myhuaweicloud.com \
  --docker-username=<username> \
  --docker-password=<password>
```

**已验证可从 quay.io 复制的镜像**：
- `prom/node-exporter:v1.8.2` ✅
- `prom/prometheus:v2.53.0` ✅

**已知限制**：`kube-state-metrics` 镜像在 registry.k8s.io / ghcr.io / Docker Hub / quay.io 均不可达，暂无法推送到 SWR。kube-state-metrics Deployment 会处于 ImagePullBackOff 状态，不影响其他采集器正常运行。

## 5. 部署采集器

```bash
cd scripts
./deploy-manifests.sh            # 部署命名空间 / RBAC / 指标 / 日志采集器
./deploy-manifests.sh --redis    # 可选：部署示例流量（Redis + exporter）
```

或者用 Python kubernetes 客户端部署（推荐，ARM64 环境下 kubectl 二进制可能不可用）：

```bash
python3 scripts/deploy-manifests.py
```

**验证**：

```bash
./verify.sh
# 或
python3 scripts/verify.py
```

预期：node-exporter、prometheus、fluent-bit Pod `Running`；node-exporter 的 `/metrics` 返回 HTTP 200；Prometheus Service 存在。

**部署状态说明**：

| 组件 | 状态 | 说明 |
|---|---|---|
| node-exporter | ✅ Running | 节点级指标采集（CPU/内存/磁盘/网络） |
| prometheus | ✅ Running | 指标聚合与查询 |
| fluent-bit | ✅ Running | 容器日志采集 |
| kube-state-metrics | ❌ ImagePullBackOff | 镜像不可达，K8s 对象状态指标暂不可用 |
| redis-demo | ✅ Running | 示例业务（Redis + exporter） |
| demo-app-statsd | ✅ Running | 示例业务（Nginx + StatsD exporter） |

## 6. 指标可视化（Grafana）

Grafana 不作为默认部署项，按需自建（例如 Deployment + 持久卷），数据源指向集群内 Prometheus：

- Prometheus Service：`http://prometheus.observability:9090`
- 导入仪表盘：`src/manifests/dashboards/dashboard-node-overview.json`、`dashboard-redis.json`

## 7. 日志对接云日志服务（生产）

默认 Fluent-Bit 输出到 stdout 便于验证。生产接入 LTS 的步骤：

1. 在 LTS（已在基础设施阶段创建日志组 / 日志流）创建日志接入点，获取上报地址与鉴权信息（AK/SK 签名）。
2. 修改 `src/manifests/logs/fluent-bit-daemonset.yaml` 的 output 段：将 `stdout` 替换为 `http` 输出，并配置 LTS 上报 endpoint、`HTTP_User` / `HTTP_Passwd` 或按 LTS 文档要求的签名头。
3. 重新 apply：`kubectl apply -f src/manifests/logs/fluent-bit-daemonset.yaml`。

## 8. 清理

```bash
cd scripts
./deploy-manifests.sh --clean       # 清理集群内采集器

cd ../infra
terraform destroy -auto-approve     # 释放云上资源
```

> 说明：`terraform destroy` 释放 Terraform 管理的资源；若已在控制台额外创建资源（如 Grafana ELB、手工上传镜像），需单独释放。

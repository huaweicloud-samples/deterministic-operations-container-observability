# ============================================================================
# 变量定义
# ============================================================================

variable "region" {
  description = "华为云区域"
  type        = string
  default     = "cn-north-4"
}

variable "project_name" {
  description = "项目名称，用于资源命名前缀"
  type        = string
  default     = "container-obs"
}

variable "vpc_cidr" {
  description = "VPC 网段"
  type        = string
  default     = "10.0.0.0/16"
}

variable "cce_cluster_flavor" {
  description = "CCE 集群规格（单 AZ 小规格，多 AZ 需 HA 规格）"
  type        = string
  default     = "cce.s1.small"
}

variable "node_flavor" {
  description = "CCE 节点规格（显式指定）"
  type        = string
  default     = "s6.large.2"
}

variable "node_count" {
  description = "CCE 节点池初始节点数"
  type        = number
  default     = 1
}

variable "node_os" {
  description = "CCE 节点操作系统（v1.36 起 EulerOS 2.9 已废弃，用华为云 EulerOS 2.0 或 Ubuntu 22.04）"
  type        = string
  default     = "Huawei Cloud EulerOS 2.0"
}

variable "node_keypair_name" {
  description = "已有 SSH 密钥对名称（用于 CCE 节点登录；先在 ECS 控制台创建密钥对）"
  type        = string
}

variable "cluster_eip_bandwidth" {
  description = "CCE 控制面公网 EIP 带宽（Mbit/s，用于 kubectl 连接集群）"
  type        = number
  default     = 5
}

variable "lts_ttl_days" {
  description = "LTS 日志组保留天数"
  type        = number
  default     = 7
}

variable "tag_project" {
  description = "资源标签 project"
  type        = string
  default     = "container-observability"
}
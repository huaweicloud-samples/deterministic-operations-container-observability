# ============================================================================
# 输出
# ============================================================================

output "cce_cluster_id" {
  description = "CCE 集群 ID"
  value       = huaweicloud_cce_cluster.main.id
}

output "cce_cluster_endpoint" {
  description = "CCE 控制面内网地址（证书 server）"
  value       = huaweicloud_cce_cluster.main.certificate_clusters[0].server
}

output "cce_public_endpoint" {
  description = "CCE 控制面公网地址（kubectl 使用）"
  value       = "https://${huaweicloud_vpc_eip.cce_api.address}:5443"
}

output "lts_group_id" {
  description = "LTS 日志组 ID"
  value       = huaweicloud_lts_group.main.id
}

output "lts_group_name" {
  description = "LTS 日志组名"
  value       = huaweicloud_lts_group.main.group_name
}

output "lts_application_stream" {
  description = "LTS 应用日志流名"
  value       = huaweicloud_lts_stream.application.stream_name
}

output "lts_host_stream" {
  description = "LTS 主机日志流名"
  value       = huaweicloud_lts_stream.host.stream_name
}
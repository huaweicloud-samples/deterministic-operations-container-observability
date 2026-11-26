# ============================================================================
# 容器镜像仓库：SWR 组织（承载采集器自定义镜像时使用；开源镜像可直拉）
# ============================================================================

resource "huaweicloud_swr_organization" "main" {
  name = var.project_name
}

# 输出
output "swr_organization" {
  description = "SWR 组织名"
  value       = huaweicloud_swr_organization.main.name
}
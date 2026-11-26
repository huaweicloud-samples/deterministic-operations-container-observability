# ============================================================================
# 可观测目标：LTS 云日志服务（日志汇聚端）
# ============================================================================

# 日志组：容器日志统一汇入（由 fluent-bit 采集上报）
resource "huaweicloud_lts_group" "main" {
  group_name  = "${var.project_name}-container-logs"
  ttl_in_days = var.lts_ttl_days
}

# 日志流：应用日志 / 主机日志两类，便于检索
resource "huaweicloud_lts_stream" "application" {
  group_id    = huaweicloud_lts_group.main.id
  stream_name = "${var.project_name}-app"
  ttl_in_days = var.lts_ttl_days
}

resource "huaweicloud_lts_stream" "host" {
  group_id    = huaweicloud_lts_group.main.id
  stream_name = "${var.project_name}-host"
  ttl_in_days = var.lts_ttl_days
}
# ============================================================================
# 容器底座：CCE 集群 + 节点池
# ============================================================================

# 控制面公网 EIP：便于本机 kubectl 连接集群
resource "huaweicloud_vpc_eip" "cce_api" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name        = "${var.project_name}-cce-api-bw"
    size        = var.cluster_eip_bandwidth
    share_type  = "PER"
    charge_mode = "traffic"
  }
}

resource "huaweicloud_cce_cluster" "main" {
  name                   = "${var.project_name}-cce"
  cluster_type           = "VirtualMachine"
  flavor_id              = var.cce_cluster_flavor
  vpc_id                 = huaweicloud_vpc.main.id
  subnet_id              = local.node_subnet_id
  container_network_type = "overlay_l2"
  authentication_mode    = "rbac"

  eip = huaweicloud_vpc_eip.cce_api.address

  tags = {
    project = var.tag_project
  }
}

resource "huaweicloud_cce_node_pool" "main" {
  cluster_id         = huaweicloud_cce_cluster.main.id
  name               = "${var.project_name}-nodepool"
  flavor_id          = var.node_flavor
  initial_node_count = var.node_count
  os                 = var.node_os
  subnet_id          = local.node_subnet_id
  scall_enable       = false

  # 节点登录：SSH 密钥对（先在 ECS 控制台创建密钥对）
  key_pair = var.node_keypair_name

  root_volume {
    size       = 40
    volumetype = "SSD"
  }
  data_volumes {
    size       = 100
    volumetype = "SSD"
  }

  tags = {
    project = var.tag_project
  }
}
# ============================================================================
# 网络底座：VPC + 子网 + 安全组
# ============================================================================

resource "huaweicloud_vpc" "main" {
  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr
}

resource "huaweicloud_vpc_subnet" "nodes" {
  name       = "${var.project_name}-node-subnet"
  vpc_id     = huaweicloud_vpc.main.id
  cidr       = cidrsubnet(var.vpc_cidr, 8, 0)
  gateway_ip = cidrhost(cidrsubnet(var.vpc_cidr, 8, 0), 1)

  availability_zone = "${var.region}a"
}

locals {
  node_subnet_id = huaweicloud_vpc_subnet.nodes.id
}

# 安全组：放行集群内网与出站
resource "huaweicloud_networking_secgroup" "main" {
  name        = "${var.project_name}-sg"
  description = "Security group for container observability"
}

resource "huaweicloud_networking_secgroup_rule" "egress_all" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main.id
}

resource "huaweicloud_networking_secgroup_rule" "egress_udp" {
  direction         = "egress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 1
  port_range_max    = 65535
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.main.id
}
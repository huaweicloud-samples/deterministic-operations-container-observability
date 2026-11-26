# ============================================================================
# Terraform 版本与 Provider
# ============================================================================

terraform {
  required_version = ">= 1.5"

  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = "~> 1.70"
    }
  }

  backend "local" {
  }
}

# ============================================================================
# Provider 配置
# ============================================================================

provider "huaweicloud" {
  region = var.region
  # 准备华为云 AK/SK（参见 README 前置条件章节）
  # export HW_ACCESS_KEY="your-access-key"
  # export HW_SECRET_KEY="your-secret-key"
}
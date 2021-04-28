terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">=0.6.3"
    }
    local = {
      source  = "hashicorp/local"
      version = ">=2.0.0"
    }
    template = {
      source  = "hashicorp/template"
      version = ">=2.2.0"
    }
  }
}

locals {
  additional_nodes = [local.lb_node, local.storage_node]
  all_nodes        = concat(local.additional_nodes, local.master_nodes, local.worker_nodes)
}

output "machines" {
  value = local.all_nodes
}

variable "master_nodes" {
  type    = number
  default = 3
}

variable "worker_nodes" {
  type    = number
  default = 2
}

variable "pool_name" {
  type    = string
  default = "default"
}

variable "volume_format" {
  type    = string
  default = "qcow2"
}

variable "os_image" {
  type    = string
  default = "centos-stream-8"
}

variable "cluster_name" {
  type    = string
  default = "kube"
}

variable "base_domain" {
  type    = string
  default = "itix.lab"
}

variable "network_name" {
  type    = string
  default = "lab"
}

variable "network_ip_range" {
  type    = string
  default = "192.168.16.0/24"
}

variable "network_mac_format" {
  type    = string
  default = "02:01:10:00:10:%02x"
}

variable "master_disk_size" {
  type    = number
  default = 120 * 1024 * 1024 * 1024
}

variable "master_vcpu" {
  type    = number
  default = 4
}

variable "master_memory_size" {
  type    = number
  default = 16 * 1024
}

variable "lb_disk_size" {
  type    = number
  default = 10 * 1024 * 1024 * 1024
}

variable "lb_vcpu" {
  type    = number
  default = 2
}

variable "lb_memory_size" {
  type    = number
  default = 4 * 1024
}

variable "storage_disk_size" {
  type    = number
  default = 120 * 1024 * 1024 * 1024
}

variable "storage_vcpu" {
  type    = number
  default = 2
}

variable "storage_memory_size" {
  type    = number
  default = 8 * 1024
}

variable "worker_disk_size" {
  type    = number
  default = 120 * 1024 * 1024 * 1024
}

variable "worker_vcpu" {
  type    = number
  default = 4
}

variable "worker_memory_size" {
  type    = number
  default = 8 * 1024
}

locals {
  master_format          = "${var.cluster_name}-master-%02d"
  master_hostname_format = "master%d.${local.network_domain}"
  worker_format          = "${var.cluster_name}-worker-%02d"
  worker_hostname_format = "worker%d.${local.network_domain}"
  storage_name           = "${var.cluster_name}-storage"
  storage_hostname       = "storage.${local.network_domain}"
  lb_name                = "${var.cluster_name}-lb"
  lb_hostname            = "lb.${local.network_domain}"
  network_domain         = "${var.cluster_name}.${var.base_domain}"
}

resource "libvirt_cloudinit_disk" "master_cloudinit" {
  name           = "${var.cluster_name}-master-cloudinit.iso"
  user_data      = file("${path.module}/templates/main/cloud-init.cfg")
  network_config = file("${path.module}/templates/main/network-config.cfg")
  pool           = var.pool_name
}

resource "libvirt_volume" "master_disk" {
  name             = "${format(local.master_format, count.index + 1)}.${var.volume_format}"
  count            = var.master_nodes
  format           = var.volume_format
  pool             = var.pool_name
  base_volume_name = "${var.os_image}.${var.volume_format}"
  size             = var.master_disk_size
}

locals {
  master_nodes = [for i in range(var.master_nodes) : {
    hostname = format(local.master_hostname_format, i + 1)
    name     = format(local.master_format, i + 1)
    ip       = cidrhost(var.network_ip_range, 11 + i)
    mac      = format(var.network_mac_format, 11 + i)
    role     = "master"
  }]
}

resource "libvirt_domain" "master" {
  count     = var.master_nodes
  name      = format(local.master_format, count.index + 1)
  vcpu      = var.master_vcpu
  memory    = var.master_memory_size
  cloudinit = libvirt_cloudinit_disk.master_cloudinit.id
  autostart = false

  cpu = {
    mode = "host-passthrough"
  }

  disk {
    volume_id = element(libvirt_volume.master_disk.*.id, count.index)
  }

  # Makes the tty0 available via `virsh console`
  console {
    type        = "pty"
    target_port = "0"
  }

  network_interface {
    network_name   = var.network_name
    mac            = element(local.master_nodes.*.mac, count.index)
    wait_for_lease = false
  }

  xml {
    xslt = file("${path.module}/network.xslt")
  }
}

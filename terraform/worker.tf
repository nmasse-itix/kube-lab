resource "libvirt_cloudinit_disk" "worker_cloudinit" {
  name           = "${var.cluster_name}-worker-cloudinit.iso"
  user_data      = file("${path.module}/templates/main/cloud-init.cfg")
  network_config = file("${path.module}/templates/main/network-config.cfg")
  pool           = var.pool_name
}

resource "libvirt_volume" "worker_disk" {
  name             = "${format(local.worker_format, count.index + 1)}.${var.volume_format}"
  count            = var.worker_nodes
  format           = var.volume_format
  pool             = var.pool_name
  base_volume_name = "${var.os_image}.${var.volume_format}"
  size             = var.worker_disk_size
}

locals {
  worker_nodes = [for i in range(var.worker_nodes) : {
    hostname = format(local.worker_hostname_format, i + 1)
    name     = format(local.worker_format, i + 1)
    ip       = cidrhost(var.network_ip_range, 21 + i)
    mac      = format(var.network_mac_format, 21 + i)
    role     = "worker"
  }]
}

resource "libvirt_domain" "worker" {
  count     = var.worker_nodes
  name      = format(local.worker_format, count.index + 1)
  vcpu      = var.worker_vcpu
  memory    = var.worker_memory_size
  cloudinit = libvirt_cloudinit_disk.worker_cloudinit.id
  autostart = false

  cpu = {
    mode = "host-passthrough"
  }

  disk {
    volume_id = element(libvirt_volume.worker_disk.*.id, count.index)
  }

  # Makes the tty0 available via `virsh console`
  console {
    type        = "pty"
    target_port = "0"
  }

  network_interface {
    network_name   = var.network_name
    mac            = element(local.worker_nodes.*.mac, count.index)
    wait_for_lease = false
  }

  xml {
    xslt = file("${path.module}/network.xslt")
  }
}

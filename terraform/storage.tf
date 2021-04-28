resource "libvirt_cloudinit_disk" "storage_cloudinit" {
  name           = "${local.storage_name}-cloudinit.iso"
  user_data      = file("${path.module}/templates/storage/cloud-init.cfg")
  network_config = file("${path.module}/templates/storage/network-config.cfg")
  pool           = var.pool_name
}

resource "libvirt_volume" "storage_os_disk" {
  name             = "${local.storage_name}-os.${var.volume_format}"
  format           = var.volume_format
  pool             = var.pool_name
  base_volume_name = "${var.os_image}.${var.volume_format}"
}

resource "libvirt_volume" "storage_data_disk" {
  name   = "${local.storage_name}-data.${var.volume_format}"
  format = var.volume_format
  pool   = var.pool_name
  size   = var.storage_disk_size
}

locals {
  storage_node = {
    hostname = local.storage_hostname
    name     = local.storage_name
    ip       = cidrhost(var.network_ip_range, 6)
    mac      = format(var.network_mac_format, 6)
    role     = "storage"
  }
}

resource "libvirt_domain" "storage" {
  name      = local.storage_name
  vcpu      = var.storage_vcpu
  memory    = var.storage_memory_size
  cloudinit = libvirt_cloudinit_disk.storage_cloudinit.id
  autostart = false

  cpu = {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.storage_os_disk.id
  }

  disk {
    volume_id = libvirt_volume.storage_data_disk.id
  }

  # Makes the tty0 available via `virsh console`
  console {
    type        = "pty"
    target_port = "0"
  }

  network_interface {
    network_name   = var.network_name
    mac            = local.storage_node.mac
    wait_for_lease = false
  }

  xml {
    xslt = file("${path.module}/network.xslt")
  }
}

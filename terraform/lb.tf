resource "libvirt_cloudinit_disk" "lb_cloudinit" {
  name           = "${local.lb_name}-cloudinit.iso"
  user_data      = data.template_file.lb_user_data.rendered
  network_config = file("${path.module}/templates/lb/network-config.cfg")
  pool           = var.pool_name
}

data "template_file" "lb_user_data" {
  template = file("${path.module}/templates/lb/cloud-init.cfg")
  vars = {
    haproxy_cfg = templatefile("${path.module}/templates/lb/haproxy.cfg", {
      master_nodes = { for i in local.master_nodes : i.name => i.ip },
      worker_nodes = { for i in local.worker_nodes : i.name => i.ip }
    })
  }
}

resource "libvirt_volume" "lb_disk" {
  name             = "${local.lb_name}.${var.volume_format}"
  format           = var.volume_format
  pool             = var.pool_name
  base_volume_name = "${var.os_image}.${var.volume_format}"
  size             = var.lb_disk_size
}

locals {
  lb_node = {
    hostname = local.lb_hostname
    name     = local.lb_name
    ip       = cidrhost(var.network_ip_range, 4)
    mac      = format(var.network_mac_format, 4)
    role     = "lb"
  }
}

resource "libvirt_domain" "lb" {
  name      = local.lb_name
  vcpu      = var.lb_vcpu
  memory    = var.lb_memory_size
  cloudinit = libvirt_cloudinit_disk.lb_cloudinit.id
  autostart = false

  cpu = {
    mode = "host-passthrough"
  }

  disk {
    volume_id = libvirt_volume.lb_disk.id
  }

  # Makes the tty0 available via `virsh console`
  console {
    type        = "pty"
    target_port = "0"
  }

  network_interface {
    network_name   = var.network_name
    mac            = local.lb_node.mac
    wait_for_lease = false
  }

  xml {
    xslt = file("${path.module}/network.xslt")
  }
}

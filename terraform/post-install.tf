resource "local_file" "ansible_inventory" {
  content         = templatefile("${path.module}/templates/inventory", { masters = local.master_nodes, workers = local.worker_nodes, lb_node = local.lb_node, api_endpoint = "api.${local.network_domain}" })
  filename        = "../kubespray/inventory/${var.cluster_name}/inventory.ini"
  file_permission = "0644"
}

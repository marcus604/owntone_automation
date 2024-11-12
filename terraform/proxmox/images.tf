resource "proxmox_virtual_environment_download_file" "ubuntu_24_cloud_image" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = var.node_name

  url = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

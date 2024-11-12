

resource "proxmox_virtual_environment_hardware_mapping_usb" "audio_capture_card" {
  name = "audio_capture_card"
  # The actual map of devices.
  map = [
    {
      id   = var.owntone_audio_in_usb_mapping
      node = var.node_name
    },
  ]
}

resource "proxmox_virtual_environment_vm" "owntone" {
  name            = "owntone"
  node_name       = var.node_name
  stop_on_destroy = true
  vm_id           = 100

  initialization {

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_data_file_id = proxmox_virtual_environment_file.ubuntu_cloud_config.id
  }

  cpu {
    cores = 1
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 512
    floating  = 512
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.ubuntu_24_cloud_image.id
    interface    = "virtio0"
    iothread     = true
    discard      = "on"
    size         = 20
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = var.owntone_mac_address
  }

  usb {
    mapping = proxmox_virtual_environment_hardware_mapping_usb.audio_capture_card.id
  }
}

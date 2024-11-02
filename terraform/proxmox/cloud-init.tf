resource "proxmox_virtual_environment_file" "ubuntu_cloud_config" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.node_name

  source_raw {
    data = <<-EOF
    #cloud-config
    users:
      - name: ansible
        groups:
          - sudo
        shell: /bin/bash
        sudo: ALL=(ALL) NOPASSWD:ALL
        ssh_authorized_keys:
          - ${trimspace(data.local_file.ansible_ssh_public_key.content)}
    runcmd:
        - apt update
        - apt upgrade -y
        - apt dist-upgrade -y
        - timedatectl set-timezone ${var.timezone}
        - reboot
    EOF

    file_name = "cloud-config.yaml"
  }
}

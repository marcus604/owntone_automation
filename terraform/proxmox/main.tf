terraform {
  required_version = ">= 1.9.8"
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "2.5.2"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.66.3"
    }
  }
}

provider "proxmox" {
  endpoint  = "https://${var.host_ip}:${var.host_port}"
  api_token = "${var.api_token_id}=${var.api_token_secret}"
  insecure  = true

  ssh {
    agent    = true
    username = var.promox_ssh_username
  }
}

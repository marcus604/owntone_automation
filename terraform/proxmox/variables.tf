variable "api_token_id" {
  type = string
}

variable "api_token_secret" {
  type = string
}

variable "host_ip" {
  type = string
}

variable "host_port" {
  type    = string
  default = "8006"
}

variable "promox_ssh_username" {
  type = string
}

variable "key_name" {
  type = string
}

variable "node_name" {
  type = string
}

variable "timezone" {
  type = string
}

variable "owntone_audio_in_usb_mapping" {
  type = string
}

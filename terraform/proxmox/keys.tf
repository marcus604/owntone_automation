data "local_file" "ansible_ssh_public_key" {
  filename = "./${var.key_name}.pub"
}
resource "ansible_playbook" "nlp-service-deployment" {
  name     = "129.69.217.248"
  playbook  = "${path.module}/nlp_service-pb.yml"
  extra_vars = {
    ansible_user                 = "external"
    ansible_ssh_private_key_file = var.ssh_key_path
    ansible_python_interpreter   = "/usr/bin/python3"
  }
}
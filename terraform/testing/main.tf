terraform {
  required_providers {
    cloudstack = {
      source  = "cloudstack/cloudstack"
      version = "0.5.0"
    }
  }
}

provider "cloudstack" {
  api_url    = var.API_URL
  api_key    = var.API_KEY
  secret_key = var.SECRET_KEY
}

resource "cloudstack_instance" "web" {
  name             = "terraform-test"
  service_offering = "DNU"
  network_id       = "bf651f13-cbae-42ae-b551-090f55e57edf"
  template         = "second-test-migration"
  zone             = "DH_KTM_EC"
}
resource "cloudstack_ssh_keypair" "default" {
  name       = "dh-ssh"
  public_key = "${file("~/.ssh/dh/dh-terraform.pub")}"
}

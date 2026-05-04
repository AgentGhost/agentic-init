locals {
  environment = var.environment
  tags = {
    environment = var.environment
    managed-by  = "terraform"
    project     = "agentic-init"
  }
}

resource "hcloud_server" "agentic" {
  name        = "agentic-${var.environment}"
  server_type = "cax21"
  image       = "ubuntu-22.04"
  location    = "fsn1"

  labels = local.tags

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.ssh_private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install -y docker.io docker-compose",
    ]
  }
}

resource "hcloud_firewall" "agentic" {
  name = "agentic-${var.environment}"

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = ["0.0.0.0/0"]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = ["0.0.0.0/0"]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = ["0.0.0.0/0"]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "8080"
    source_ips = ["0.0.0.0/0"]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "9092"
    source_ips = ["0.0.0.0/0"]
  }
}

resource "hcloud_firewall_attachment" "agentic" {
  firewall_id = hcloud_firewall.agentic.id
  server_ids  = [hcloud_server.agentic.id]
}
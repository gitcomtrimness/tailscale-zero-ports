# Latest Ubuntu 24.04 LTS image from Canonical.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

resource "random_password" "db" {
  length  = 24
  special = false
}

# Single-use, one-hour key the server uses once to join as tag:prod-db.
resource "tailscale_tailnet_key" "db" {
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  tags          = ["tag:prod-db"]
  description   = "prod-db bootstrap"

  # The tag must exist in the policy before a key can carry it.
  depends_on = [tailscale_acl.policy]
}

resource "aws_instance" "db" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.prod.id
  vpc_security_group_ids = [aws_security_group.prod.id]

  # No key_name: there is no SSH key. Shell access is Tailscale SSH only.

  user_data = templatefile("${path.module}/cloud-init/db.sh.tftpl", {
    ts_auth_key = tailscale_tailnet_key.db.key
    db_password = random_password.db.result
  })
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  tags = { Name = "prod-db" }
}

output "prod_db_public_ip" {
  description = "Used only to prove nothing is reachable from the internet."
  value       = aws_instance.db.public_ip
}
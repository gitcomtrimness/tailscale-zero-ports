# Single-use, one-hour key the server uses once to join as tag:prod-app.
resource "tailscale_tailnet_key" "app" {
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  tags          = ["tag:prod-app"]
  description   = "prod-app bootstrap"

  # The tag must exist in the policy before a key can carry it.
  depends_on = [tailscale_acl.policy]
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.prod.id
  vpc_security_group_ids = [aws_security_group.prod.id]

  # No key_name: there is no SSH key. Shell access is Tailscale SSH only.

  user_data = templatefile("${path.module}/cloud-init/app.sh.tftpl", {
    ts_auth_key = tailscale_tailnet_key.app.key
  })
  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required" # IMDSv2 only
  }

  tags = { Name = "prod-app" }
}

output "prod_app_public_ip" {
  description = "Used only to prove nothing is reachable from the internet."
  value       = aws_instance.app.public_ip
}
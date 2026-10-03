# Smoke test: prove both providers can authenticate. Builds nothing.
data "aws_caller_identity" "me" {}

data "tailscale_devices" "all" {}

output "aws_identity" {
  value = data.aws_caller_identity.me.arn
}

output "tailnet_device_count" {
  value = length(data.tailscale_devices.all.devices)
}
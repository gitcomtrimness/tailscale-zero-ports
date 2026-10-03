# The tailnet policy lives in the repo and is applied by Terraform,
# so every access change is a reviewed commit.
resource "tailscale_acl" "policy" {
  acl = file("${path.module}/../policy/policy.hujson")

  # A brand-new tailnet starts with Tailscale's default allow-all policy.
  # This lets Terraform take ownership of it on first apply.
  overwrite_existing_content = true
}

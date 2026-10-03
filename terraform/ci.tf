# Trust GitHub Actions' identity tokens, but only from this repo's main branch.
# The workflow exchanges its token for a short-lived key and joins as an
# ephemeral tag:ci node. No Tailscale secret is stored in GitHub.
resource "tailscale_federated_identity" "ci" {
  description = "GitHubActionsCI"
  issuer      = "https://token.actions.githubusercontent.com"
  subject     = "repo:gitcomtrimness/tailscale-zero-ports:ref:refs/heads/main"
  scopes      = ["auth_keys"]
  tags        = ["tag:ci"]

  # tag:ci must exist in the policy first.
  depends_on = [tailscale_acl.policy]
}

# Not secrets: the client ID and audience only work together with a
# GitHub-signed token from the repo and branch above.
output "ci_client_id" {
  value = tailscale_federated_identity.ci.id
}

output "ci_audience" {
  # Tailscale generates the audience as api.tailscale.com/<client ID>
  # when one isn't specified.
  value = coalesce(
    tailscale_federated_identity.ci.audience,
    "api.tailscale.com/${tailscale_federated_identity.ci.id}",
  )
}

# The migration job still needs the database login. This is the one real
# secret CI holds, and the README names it as what Tailscale PAM would remove.
output "db_password" {
  value     = random_password.db.result
  sensitive = true
}
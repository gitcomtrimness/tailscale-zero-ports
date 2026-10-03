# Trust GitHub Actions' identity tokens, but only from this repo's main branch.
# GitHub's subject includes the account and repo IDs (name@id), so a deleted
# and recreated repo with the same name is NOT trusted.
resource "tailscale_federated_identity" "ci" {
  description = "GitHubActionsCI"
  issuer      = "https://token.actions.githubusercontent.com"
  subject     = "repo:gitcomtrimness@232724278/tailscale-zero-ports@1403538242:ref:refs/heads/main"
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
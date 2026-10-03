#!/usr/bin/env bash
# validate.sh: prove the allowed paths work AND the denied paths fail.
#
# Run it once as each identity (switch with `tailscale switch <account>`):
#   engineer   -> MeridiianHealth@github
#   contractor -> MeridianContractor@github
# Rows 7-9 (CI) run inside GitHub Actions: .github/workflows/migrate.yml
#
# Exits non-zero if any result differs from what the policy says it should be.
set -uo pipefail
cd "$(dirname "$0")/.."

STATUS_JSON=$(tailscale status --json)
SUFFIX=$(printf '%s' "$STATUS_JSON" | python3 -c 'import json,sys; print(json.load(sys.stdin)["CurrentTailnet"]["MagicDNSSuffix"])')
ME=$(printf '%s' "$STATUS_JSON" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d["User"][str(d["Self"]["UserID"])]["LoginName"])')
APP="prod-app.${SUFFIX}"
DB_PUB=$(terraform -chdir=terraform output -raw prod_db_public_ip)
APP_PUB=$(terraform -chdir=terraform output -raw prod_app_public_ip)

pass=0
fail=0

# check "<label>" <allow|deny> <command...>
check() {
  local label=$1 expect=$2
  shift 2
  local got=deny
  if "$@" >/dev/null 2>&1; then got=allow; fi
  if [[ "$got" == "$expect" ]]; then
    printf 'PASS  %-48s expected %-5s got %s\n' "$label" "$expect" "$got"
    pass=$((pass + 1))
  else
    printf 'FAIL  %-48s expected %-5s got %s\n' "$label" "$expect" "$got"
    fail=$((fail + 1))
  fi
}

# macOS nc needs -G for a connect timeout; -w alone waits ~75s on dropped packets.
  if [[ "$(uname)" == "Darwin" ]]; then
     tcp() { nc -z -G 3 -w 3 "$1" "$2"; }
  else
     tcp() { nc -z -w 3 "$1" "$2"; }
  fi
https_ok()    { curl -sS -m 10 -o /dev/null "https://${APP}"; }
app_sees_db() { curl -sS -m 10 "https://${APP}" | grep -q '>reachable<'; }
ssh_ok()      { tailscale ssh "ubuntu@$1" true </dev/null; }
resolves()    { tailscale ip -4 "$1"; }

echo "Tailnet: ${SUFFIX}"
echo "Signed in as: ${ME}"
echo

case "$ME" in
  MeridiianHealth@github)
    echo "--- engineer (group:eng) ---"
    check "1  eng -> prod-app:443 (HTTPS)"          allow https_ok
    check "2  eng -> prod-db:5432 (Postgres)"       allow tcp prod-db 5432
    check "3  eng -> prod-db (Tailscale SSH)"       allow ssh_ok prod-db
    check "3b eng -> prod-app (Tailscale SSH)"      allow ssh_ok prod-app
    check "11 prod-app -> prod-db:5432 (via app)"   allow app_sees_db
    echo
    echo "For the contractor run, first set:"
    echo "  export PROD_DB_TS_IP=$(tailscale ip -4 prod-db)"
    ;;
  MeridianContractor@github)
    echo "--- contractor (group:contractors) ---"
    check "4  contractor -> prod-app:443 (HTTPS)"   allow https_ok
    check "5  contractor -> prod-db (name visible)" deny  resolves prod-db
    if [[ -n "${PROD_DB_TS_IP:-}" ]]; then
      check "5b contractor -> prod-db:5432 (by IP)" deny  tcp "$PROD_DB_TS_IP" 5432
    else
      echo "SKIP  5b (set PROD_DB_TS_IP; the engineer run prints it)"
    fi
    check "6  contractor -> prod-app:22"            deny  tcp "$APP" 22
    ;;
  *)
    echo "Unknown identity: ${ME}"
    exit 2
    ;;
esac

echo
echo "--- public internet (row 10) ---"
for p in 22 443 5432; do
  check "10 internet -> prod-db public :${p}"  deny tcp "$DB_PUB" "$p"
done
for p in 22 443 8080; do
  check "10 internet -> prod-app public :${p}" deny tcp "$APP_PUB" "$p"
done

echo
echo "Rows 7-9 (CI) are checked inside GitHub Actions."
echo "Result: ${pass} passed, ${fail} failed"
[[ "$fail" -eq 0 ]]

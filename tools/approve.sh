#!/usr/bin/env bash
# Approve a new date: writes manifest.json and signs it with your minisign key.
#
#   tools/approve.sh 2026/09/27              # move users to this Arch snapshot day
#   tools/approve.sh 2026/09/27 mesa,foo     # ...and hold these packages
#
# The private key stays on your machine (default ~/.minisign/zohara.key).
# After it finishes, review the diff, then commit and push.
set -euo pipefail

date_arg="${1:?usage: approve.sh YYYY/MM/DD [held,packages]}"
held="${2:-}"
key="${ZOHARA_MINISIGN_KEY:-$HOME/.minisign/zohara.key}"
min_version="${ZOHARA_MIN_UPDATER:-0.1.0}"
here="$(cd "$(dirname "$0")/.." && pwd)"

[[ "$date_arg" =~ ^[0-9]{4}/[0-9]{2}/[0-9]{2}$ ]] || { echo "Date must look like 2026/09/27" >&2; exit 1; }
[ -f "$key" ] || { echo "No signing key at $key (see README: minisign -G)" >&2; exit 1; }
command -v minisign >/dev/null || { echo "minisign is not installed" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is not installed" >&2; exit 1; }

# The archive must actually have that day, or every user's update would fail.
url="https://archive.archlinux.org/repos/${date_arg}/core/os/x86_64/core.db"
curl --fail --silent --head --location --max-time 30 "$url" >/dev/null || { echo "The Arch Linux Archive has no snapshot for $date_arg ($url)" >&2; exit 1; }

# Never go backwards: clients refuse it, so signing it would only strand users.
if [ -f "$here/manifest.json" ]; then
  current="$(jq -r .approved_date "$here/manifest.json")"
  if [[ "$date_arg" < "$current" ]]; then
    echo "$date_arg is older than the current $current" >&2
    exit 1
  fi
fi

jq -n --arg d "$date_arg" --arg h "$held" --arg v "$min_version" \
  '{approved_date: $d, held_packages: ($h | split(",") | map(select(. != ""))), min_updater_version: $v}' \
  > "$here/manifest.json"

minisign -S -s "$key" -m "$here/manifest.json" -x "$here/manifest.json.minisig" -t "approved $date_arg"
echo "Signed. Now: git add manifest.json manifest.json.minisig && git commit && git push"

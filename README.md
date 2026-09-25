# Zohara update pipeline

Zohara users never follow live Arch. They follow a **pinned date**: the official
packages as the Arch Linux Archive had them on `approved_date`. Approving an
update means moving that date forward.

| File | What |
|---|---|
| `manifest.json` | `approved_date`, `held_packages`, `min_updater_version` |
| `manifest.json.minisig` | minisign signature over `manifest.json` |
| `tools/approve.sh` | writes and signs a new manifest (run on your machine) |

Zohara Store fetches both files, checks the signature against the public key in
the OS (`/usr/share/zohara/manifest.pub`), refuses anything unsigned, tampered
with or older than what the computer already has, then points the mirror at the
approved day and runs one full upgrade.

## One-time setup: the signing key

```bash
mkdir -p ~/.minisign
minisign -G -p zohara-manifest.pub -s ~/.minisign/zohara.key
```

Keep `~/.minisign/zohara.key` (and its password) off GitHub and off shared
machines. Give the public half to the OS: copy `zohara-manifest.pub` to
`zohara-store-rs/data/manifest.pub` in the `zohara` repo and push. Until that file
exists, the Store keeps the old behaviour and does not gate system updates.

## Approving a date

```bash
tools/approve.sh 2026/09/27
git add manifest.json manifest.json.minisig && git commit -m "Approve 2026/09/27" && git push
```

`tools/approve.sh 2026/09/27 mesa` also holds `mesa` at the installed version.
Prefer moving to a different date over holding single packages: holding one
package while the rest updates is a partial upgrade.

Later phases (risk tiers, VM upgrade tests, monitoring, approval bot) plug into
this: they decide *which* date gets approved.

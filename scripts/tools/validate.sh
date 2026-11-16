#!/usr/bin/env bash
# Offline checks for the whole repository. Run before every commit; CI runs the same file.
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
fail=0; step() { printf '\n== %s\n' "$1"; }; bad() { echo "FAIL: $1"; fail=1; }

step "shell syntax"
for f in scripts/*/*.sh ansible/scripts/*.sh ansible/tests/*.sh; do [ -f "$f" ] && { bash -n "$f" && echo "ok $f" || bad "$f"; }; done

step "YAML syntax (monitoring/ and ansible inventory)"
python3 - <<'PY' || fail=1
import sys, pathlib, yaml
ok = True
files = [p for p in pathlib.Path("monitoring").rglob("*.y*ml")] + list(pathlib.Path("ansible/inventory").rglob("*.y*ml")) + [p for p in pathlib.Path(".github").rglob("*.y*ml")]
for p in files:
    try:
        list(yaml.safe_load_all(p.read_text(encoding="utf-8")))
    except Exception as e:
        print("FAIL", p, str(e).splitlines()[0]); ok = False
print(f"checked {len(files)} files")
sys.exit(0 if ok else 1)
PY

step "Prometheus targets generate from the inventory"
tmp="$(mktemp -d)"
python3 monitoring/prometheus/gen-targets.py --inventory ansible/inventory/production.yml \
  --ports ansible/inventory/group_vars/all/20-ports.yml --out "$tmp" --cluster test >/dev/null 2>&1 \
  && [ "$(ls "$tmp" | wc -l)" -ge 10 ] && echo "ok: $(ls "$tmp" | wc -l) target files" || bad "gen-targets.py"
python3 - "$tmp" <<'PY' || fail=1
import json, sys, pathlib, yaml
sd = set(p.name for p in pathlib.Path(sys.argv[1]).glob("*.json"))
cfg = yaml.safe_load(open("monitoring/prometheus/prometheus.yml"))
used = set()
for j in cfg["scrape_configs"]:
    for f in j.get("file_sd_configs", []):
        for pat in f["files"]:
            used.add(pat.rsplit("/", 1)[1])
missing = used - sd
print("prometheus.yml references", len(used), "file_sd files;", "missing:", sorted(missing) or "none")
sys.exit(1 if missing else 0)
PY
rm -rf "$tmp"

step "promtool (only if installed)"
if command -v promtool >/dev/null; then
  promtool check rules monitoring/prometheus/alerts/*.yml || bad "alert rules"
else echo "skipped: promtool not installed"; fi

step "dashboard sanitizer"
python3 scripts/monitoring/sanitize-dashboards.py --check monitoring/grafana/dashboards || bad "unsanitized dashboard"

step "dashboard sanitizer self-test"
t="$(mktemp -d)"; cp tests/fixtures/dashboard-sample.json "$t/"
python3 scripts/monitoring/sanitize-dashboards.py "$t" >/dev/null
python3 - "$t/dashboard-sample.json" <<'PY' || bad "sanitizer self-test"
import json, sys
d = json.load(open(sys.argv[1]))
assert d["id"] is None and "version" not in d
assert d["panels"][0]["datasource"]["uid"] == "prometheus"
print("ok")
PY
rm -rf "$t"

step "Markdown relative links"
python3 - <<'PY' || fail=1
import re, pathlib, sys
bad = 0
for md in pathlib.Path(".").rglob("*.md"):
    if any(x in md.parts for x in (".git", "offline_packages")): continue
    for m in re.finditer(r"\]\(([^)#\s]+)(#[^)]*)?\)", md.read_text(encoding="utf-8")):
        tgt = m.group(1)
        if re.match(r"[a-z]+:", tgt) or tgt.startswith("mailto"): continue
        if not (md.parent / tgt).exists():
            print("broken link:", md, "->", tgt); bad += 1
print("broken links:", bad)
sys.exit(1 if bad else 0)
PY

step "secret scan"
bash scripts/tools/check-secrets.sh || fail=1

echo; [ "$fail" -eq 0 ] && echo "validate: all checks passed" || echo "validate: FAILED"
exit "$fail"

#!/usr/bin/env python3
"""Make exported Grafana dashboards safe to publish.

* sets the numeric id to null and drops the version
* points every panel at the provisioned data source (uid: prometheus)
* masks private IPv4 addresses and any term listed in .forbidden-terms
* reports (does not fix) anything that still looks like a secret

    python3 scripts/monitoring/sanitize-dashboards.py [path]      # default: monitoring/grafana/dashboards
    python3 scripts/monitoring/sanitize-dashboards.py --check     # exit 1 if a file would change
"""
import json, pathlib, re, sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
PRIVATE_IP = re.compile(r"\b(10\.\d{1,3}|172\.(1[6-9]|2\d|3[01])|192\.168)\.\d{1,3}\.\d{1,3}\b")
SECRETISH = re.compile(r"(?i)(password|secret|token|api[_-]?key)\"?\s*[:=]\s*\"[^\"<$]{6,}\"")


def forbidden_terms():
    f = ROOT / ".forbidden-terms"
    if not f.exists():
        return []
    return [re.compile(t) for t in f.read_text().splitlines() if t and not t.startswith("#")]


def _rel(f):
    try:
        return str(f.relative_to(ROOT))
    except ValueError:
        return str(f)


def fix_datasources(node):
    if isinstance(node, dict):
        ds = node.get("datasource")
        if isinstance(ds, dict) and ds.get("type") == "prometheus":
            node["datasource"] = {"type": "prometheus", "uid": "prometheus"}
        elif isinstance(ds, str) and ds not in ("-- Grafana --", "-- Mixed --"):
            node["datasource"] = {"type": "prometheus", "uid": "prometheus"}
        for v in node.values():
            fix_datasources(v)
    elif isinstance(node, list):
        for v in node:
            fix_datasources(v)


def main():
    check = "--check" in sys.argv
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    base = pathlib.Path(args[0]) if args else ROOT / "monitoring/grafana/dashboards"
    terms = forbidden_terms()
    changed = warned = 0
    for f in sorted(base.rglob("*.json")):
        raw = f.read_text(encoding="utf-8")
        d = json.loads(raw)
        d["id"] = None
        d.pop("version", None)
        fix_datasources(d)
        text = json.dumps(d, indent=2, ensure_ascii=False) + "\n"
        text = PRIVATE_IP.sub("<IP>", text)
        for t in terms:
            text = t.sub("<MASKED>", text)
        if SECRETISH.search(text):
            print(f"WARNING possible secret in {f}", file=sys.stderr)
            warned += 1
        if text != raw:
            changed += 1
            print(("would change: " if check else "sanitized: ") + _rel(f))
            if not check:
                f.write_text(text, encoding="utf-8")
    print(f"{changed} file(s) {'need' if check else 'were'} sanitizing, {warned} warning(s)")
    sys.exit(1 if (check and changed) or warned else 0)


if __name__ == "__main__":
    main()

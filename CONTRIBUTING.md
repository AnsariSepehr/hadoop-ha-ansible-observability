# Contributing

1. **Never commit real values.** Copy `.forbidden-terms.example` to `.forbidden-terms`, list your real domain, hosts and users, and run `bash scripts/tools/validate.sh` before every commit. It includes the secret scan.
2. Install the pre-commit hook:
   ```bash
   printf '#!/bin/sh\nbash scripts/tools/validate.sh\n' > .git/hooks/pre-commit && chmod +x .git/hooks/pre-commit
   ```
3. Use only the placeholders from [docs/prerequisites.md](docs/prerequisites.md#masking-legend). Inventory examples use the documentation range `192.0.2.0/24`.
4. Mark anything unverified as **unverified**.
5. Add each bug to [docs/troubleshooting.md](docs/troubleshooting.md) and each limitation to [docs/known-limitations.md](docs/known-limitations.md).
6. New service? Follow [docs/adding-a-service.md](docs/adding-a-service.md).
7. Dashboards: export, then run `python3 scripts/monitoring/sanitize-dashboards.py`. Do not commit raw exports.
8. Scripts: `set -euo pipefail`, no secrets on the command line, idempotent where possible.

#!/usr/bin/env bash
# Offline test entry point. Static checks run without Ansible; Ansible checks are
# mandatory on a real control node and explicitly reported as skipped elsewhere.
set -euo pipefail
cd "$(dirname "$0")/.."

python3 tests/static-check.py

if command -v yamllint >/dev/null 2>&1; then
  echo '== yamllint'
  yamllint .
else
  echo 'SKIP: yamllint is not installed (install it on the Ansible control node).'
fi

if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo 'SKIP: ansible-playbook is not installed; syntax-check and template-render tests were not run.'
  echo 'Install ansible-core >= 2.14, then rerun tests/run-tests.sh before deployment.'
  exit 2
fi

echo '== Ansible syntax-check'
while IFS= read -r f; do
  case "$f" in *.bak*) continue ;; esac
  ansible-playbook -i 'localhost,' "$f" --syntax-check >/dev/null
done < <(find playbooks -type f -name '*.yml' | sort)

echo '== Render all templates (requires the inventory Vault password)'
if [[ -n "${ANSIBLE_VAULT_PASSWORD_FILE:-}" ]]; then
  vault_args=(--vault-password-file "$ANSIBLE_VAULT_PASSWORD_FILE")
else
  vault_args=(--ask-vault-pass)
fi
ansible-playbook -i inventory/local-test.yml tests/render-templates.yml "${vault_args[@]}" \
  -e allow_default_secrets=true -e hive_mysql_host_override=192.0.2.99

if command -v xmllint >/dev/null 2>&1; then
  while IFS= read -r f; do xmllint --noout "$f"; done < <(find /tmp/kadoop-render -type f -name '*.xml' | sort)
else
  echo 'SKIP: xmllint is not installed.'
fi

echo 'ALL AVAILABLE TESTS PASSED'

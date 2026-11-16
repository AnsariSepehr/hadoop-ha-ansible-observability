.PHONY: preflight install start stop status clean test

# The encrypted inventory/group_vars/all/secrets.yml is loaded by every
# Ansible command. Prompt by default; override with:
#   make install VAULT_ARGS="--vault-password-file /secure/path/vault-pass"
VAULT_ARGS ?= --ask-vault-pass
CONFIRM_DESTROY_DATA ?= no

preflight:
	ansible-playbook playbooks/system/preflight.yml $(VAULT_ARGS)

install:
	ansible-playbook playbooks/site.yml $(VAULT_ARGS)

start:
	ansible-playbook playbooks/start-cluster.yml $(VAULT_ARGS)

stop:
	ansible-playbook playbooks/stop-cluster.yml $(VAULT_ARGS)

status:
	ansible-playbook playbooks/status-cluster.yml $(VAULT_ARGS)

clean:
	ansible-playbook playbooks/clean-all.yml $(VAULT_ARGS) -e confirm_destroy_data=$(CONFIRM_DESTROY_DATA)

test:
	tests/run-tests.sh

# Full cluster cleanup

`playbooks/clean-all.yml` is the destructive teardown for the Kadoop project.
It first stops current and legacy units, runs each component's cleanup, then
removes leftover unit files, project-managed profiles/tmpfiles/tuning files,
Hadoop/JVM tarball installations, JMX exporter files, runtime/log directories,
the managed `/etc/hosts` block, and project-generated IDs/certificates.

## Run

```bash
ansible-playbook -i inventory/production.yml playbooks/clean-all.yml \
  --ask-vault-pass -b -e confirm_destroy_data=yes
```

The confirmation flag is mandatory because this removes HDFS, YARN, ZooKeeper,
Kafka, MySQL, and application data. Verify the inventory before running.

By default, it **keeps OS-managed Java RPM packages** and the `hadoop`/`kafka`
service accounts. To remove those service accounts and their home directories
as a separate explicit choice, add:

```bash
-e remove_service_accounts=yes
```

Java RPM packages are deliberately not auto-erased: the RPMs may be shared with
other applications on the operating system. Offline package archives are never
removed from the Ansible control node.

# kadoop-ha-ansible v2

> Reviewed build: 2026-10-31. See `docs/BUGFIX-2026-10.md` and `TEST-REPORT.md` for the corrections and the exact validation boundary.

نصب **آفلاین**، **پارامتری** و **قابل‌تکرار** یک پلتفرم داده‌ی کامل روی هر کلاستر RHEL-family (۸ و ۹):

| جزء | نسخه | نقش |
|---|---|---|
| Hadoop HDFS + YARN + MapReduce | 3.3.6 | HA کامل: ۲ NameNode + ZKFC + JournalNode، ۲ ResourceManager |
| ZooKeeper | 3.8.4 | هماهنگی و Failover خودکار |
| MySQL Group Replication | 8.0.42 | دیتابیس Metastore (Single-Primary) |
| Hive | 3.1.3 | Metastore + HiveServer2 |
| Spark | 3.5.4 | روی YARN + History Server + اتصال به Hive |
| Kafka | 4.0.0 | KRaft (بدون ZooKeeper) |
| JMX Exporter | 1.1.0 | متریک Prometheus برای همه‌ی سرویس‌ها |

> هیچ Collection خارجی (ansible.posix، community.*) لازم نیست؛ فقط `ansible-core ≥ 2.14` با ماژول‌های `ansible.builtin`.
> هیچ دسترسی اینترنتی لازم نیست؛ حتی `dnf` با `--disablerepo='*'` اجرا می‌شود.

---

## ۱. شروع سریع

```bash
# ۱) بسته‌ها را در offline_packages بگذارید (فهرست: offline_packages/MANIFEST.md)
scripts/organize-offline-packages.sh /path/to/flat/downloads      # اگر فایل‌ها تخت‌اند

# ۲) کلاستر خودتان را در Inventory تعریف کنید  (فقط همین یک فایل)
vi inventory/production.yml

# ۳) رمزها را عوض و رمزنگاری کنید
vi inventory/group_vars/all/secrets.yml
ansible-vault encrypt inventory/group_vars/all/secrets.yml        # سپس اجرا با --ask-vault-pass

# ۴) پیش‌بررسی (Inventory، رمزها، وجود بسته‌ها، OS نودها)
make preflight          # رمز Vault را می‌پرسد

# ۵) نصب کامل
make install            # = ansible-playbook playbooks/site.yml --ask-vault-pass
make status
```

برای استفاده از Vault password file به‌جای prompt: `make install VAULT_ARGS="--vault-password-file /secure/path/vault-pass"`.
پاک‌سازی کامل فقط با تأیید صریح انجام می‌شود: `make clean CONFIRM_DESTROY_DATA=yes VAULT_ARGS="--ask-vault-pass"`.

پیش‌نیاز نودها: دسترسی SSH کاربر root (کلید) ، `tar` ، `gzip` ، `sudo` ، `runuser` ، پایتون ۳ و ساعت همگام (chrony).
پیش‌نیاز Control Node: `ansible-core`, `python3`, `ssh-keygen`.

## ۲. ساختار پروژه

```
├── ansible.cfg
├── Makefile                     make preflight|install|start|stop|status|clean|test
├── .generated/                  شناسه‌های پایدار Kafka/MySQL (حذف نکنید)
├── inventory/
│   ├── production.yml           ← تنها فایلی که برای هر کلاستر ویرایش می‌شود
│   ├── local-test.yml           fixture تست (همه‌ی نودها = ماشین محلی)
│   └── group_vars/all/
│       ├── 00-cluster.yml       نام کلاستر، کاربر، مسیرها، سوییچ‌ها (JMX/SSL/Firewall…)
│       ├── 10-versions.yml      نسخه‌ها + مسیر بسته‌ها + کاتالوگ Java
│       ├── 20-ports.yml         همه‌ی پورت‌ها (+ پورت JMX هر سرویس)
│       ├── 30-derived.yml       مقادیر مشتق‌شده از Inventory (دست نزنید)
│       ├── 40-resources.yml     حافظه‌ی YARN/Spark/Hive/Kafka (auto یا fixed)
│       └── secrets.yml          رمزها (vault)
├── offline_packages/<نرم‌افزار>/<نرم‌افزار>-<نسخه>/…       (MANIFEST.md)
├── roles/                       منطق (بدون نسخه)  common · java · zookeeper · hadoop · mysql · hive · spark · kafka · jmx_exporter
├── playbooks/
│   ├── site.yml  start-cluster.yml  stop-cluster.yml  status-cluster.yml  clean-all.yml
│   ├── system/        preflight.yml  initialize.yml
│   ├── zookeeper/3.8.4/    install start stop status clean
│   ├── hadoop/3.3.6/       install bootstrap-ha yarn ssl start stop status clean
│   ├── mysql/8.0.42/       install status bootstrap-after-outage clean
│   ├── hive/3.1.3/         install start stop refresh-metastore-endpoint clean
│   ├── spark/3.5.4/        install clean
│   ├── kafka/4.0.0/        install clean
│   └── monitoring/jmx-exporter/1.1.0/   install
├── scripts/  cluster.sh  organize-offline-packages.sh
├── tests/    run-tests.sh  render-templates.yml
└── docs/     OPERATIONS.md  MIGRATION-FROM-V1.md
```

**نسخه‌ها:** پوشه‌ی هر Playbook یک نسخه را هدف می‌گیرد و در ابتدا بررسی می‌کند `*_version` با پوشه یکی باشد.
برای نسخه‌ی جدید (مثلاً Hadoop 3.4.0): پوشه‌ی بسته را بسازید، `playbooks/hadoop/3.3.6` را به `3.4.0` کپی کنید،
`expected_version` را عوض کنید، `hadoop_version` را در `10-versions.yml` تغییر دهید.
نصب روی دیسک هم نسخه‌دار است: `/opt/hadoop-3.3.6` با لینک ثابت `/opt/hadoop`.

## ۳. Inventory – تنها نقطه‌ی پیکربندی کلاستر

هر ماشین یک‌بار با نام و IP تعریف می‌شود و با عضویت در گروه‌ها نقش می‌گیرد:
`namenodes` (۲) · `journalnodes` (≥۳ فرد) · `zookeepers` (≥۳ فرد) · `datanodes` · `nodemanagers` · `resourcemanagers` ·
`history_servers` · `mysql` (۱/۳/۵) · `hive_servers` · `spark_clients` · `spark_history_servers` · `kafka_brokers` (≥۳).
گروه خالی = آن سرویس نصب نمی‌شود. هیچ IP، نام نود یا نقش در Playbook ها/قالب‌ها hard-code نیست؛
quorum ها، شناسه‌ی nn/rm/myid/kafka node.id، آدرس‌ها، هم‌ساخته می‌شوند.

## ۴. اجرای مرحله‌ای (به‌جای site.yml)

```bash
ansible-playbook playbooks/system/preflight.yml --ask-vault-pass
ansible-playbook playbooks/system/initialize.yml --ask-vault-pass
ansible-playbook playbooks/monitoring/jmx-exporter/1.1.0/install.yml --ask-vault-pass
ansible-playbook playbooks/zookeeper/3.8.4/install.yml --ask-vault-pass
ansible-playbook playbooks/hadoop/3.3.6/install.yml --ask-vault-pass
ansible-playbook playbooks/hadoop/3.3.6/bootstrap-ha.yml --ask-vault-pass  # Format فقط وقتی متادیتا وجود ندارد
ansible-playbook playbooks/hadoop/3.3.6/yarn.yml --ask-vault-pass
ansible-playbook playbooks/mysql/8.0.42/install.yml --ask-vault-pass
ansible-playbook playbooks/hive/3.1.3/install.yml --ask-vault-pass
ansible-playbook playbooks/spark/3.5.4/install.yml --ask-vault-pass
ansible-playbook playbooks/kafka/4.0.0/install.yml --ask-vault-pass
```
Playbookها برای اجرای مجدد طراحی شده‌اند؛ عملیات مخرب فقط با
`-e confirm_destroy_data=yes` اجرا می‌شود (`clean-all.yml` ، `-e hdfs_force_reformat=true` ، `-e hive_reinit_schema=true` ، `-e mysql_force_reinit=true`).

## ۵. تنظیمات مهم

| می‌خواهم… | کجا |
|---|---|
| آدرس‌دهی با hostname به‌جای IP | `address_mode: hostname` (و `manage_etc_hosts: true`) |
| غیرفعال‌کردن JMX | `jmx_exporter_enabled: false` |
| Java 11 برای Hadoop | `java_default_version: "11"` (فایل در `offline_packages/java/openjdk-11/`) |
| حافظه‌ی دستی YARN | `resource_mode: fixed` + `yarn_*_fixed_mb` |
| بازکردن پورت‌ها در firewalld | `manage_firewall: true` |
| HTTPS برای وب‌رابط‌های HDFS | `hadoop_ssl_enabled: true` سپس `playbooks/hadoop/3.3.6/ssl.yml` (`hadoop_ssl_mode: selfsigned|custom`) |
| Hive به MySQL Router/VIP | `hive_mysql_host_override: <addr>` |
| بعد از تغییر Primary در MySQL | `playbooks/hive/3.1.3/refresh-metastore-endpoint.yml` |

## ۶. تست بدون سرور

```bash
make test        # static checks + (on the control node) yamllint, Ansible syntax-check, template render, XML validation
```

اگر `secrets.yml` با Ansible Vault رمزنگاری شده، `make test` رمز Vault را می‌پرسد؛ برای اجرای غیرتعاملی `ANSIBLE_VAULT_PASSWORD_FILE=/secure/path make test` را اجرا کنید. سایر فرمان‌های Make نیز به‌طور پیش‌فرض `--ask-vault-pass` دارند؛ برای استفاده از password file، `VAULT_ARGS="--vault-password-file /secure/path"` را به فرمان اضافه کنید.

اجرای سریع: `make preflight` سپس `make install`؛ وضعیت با `make status` و توقف با `make stop`. پاک‌سازی کامل فقط با `make clean CONFIRM_DESTROY_DATA=yes` انجام می‌شود.

جزئیات عملیات روزمره، عیب‌یابی و فهرست تغییرات نسبت به نسخه‌ی ۱: `docs/`.

## Full destructive cleanup

To stop all project services and remove the installed Kadoop stack and its data:

```bash
ansible-playbook -i inventory/production.yml playbooks/clean-all.yml --ask-vault-pass -b -e confirm_destroy_data=yes
```

Review `docs/CLEAN-ALL.md` first. This deletes HDFS/YARN, ZooKeeper, Kafka and MySQL data. OS-managed Java RPMs and service accounts are kept unless explicitly requested.

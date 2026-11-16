# تغییرات نسبت به نسخه‌ی ۱ و ایرادهای رفع‌شده

## نگاشت Playbook ها

| v1 | v2 |
|---|---|
| 01-initialize | `system/initialize.yml` (role `common`) |
| 02-install-java8/11 | role `java` (خودکار، بر اساس `*_java_version`) |
| 03-install-hadoop + 04-configure | `hadoop/3.3.6/install.yml` |
| 05-format-hadoop-ha + 06/07-zookeeper | `zookeeper/3.8.4/install.yml` سپس `hadoop/3.3.6/bootstrap-ha.yml` |
| 05-1/05-2 ssl | `hadoop/3.3.6/ssl.yml` (`hadoop_ssl_mode`) |
| 08-install-yarn | `hadoop/3.3.6/yarn.yml` |
| 09-install/clean/status-mysql | `mysql/8.0.42/{install,clean,status}.yml` |
| 10-install/configure/start/clean-hive، 10-drop-metastore | `hive/3.1.3/{install,start,stop,clean}.yml` (drop: `-e drop_metastore_db=true`) |
| 11-start-cluster، start-all.sh، stop-all.sh | `start-cluster.yml` ، `stop-cluster.yml` |
| 12-install-jmx-exporter | `monitoring/jmx-exporter/1.1.0/install.yml` + تنظیم خودکار در unit ها |
| 13-install/clean-spark | `spark/3.5.4/{install,clean}.yml` |
| 14-install/clean-kafka | `kafka/4.0.0/{install,clean}.yml` |
| 99-cluster-status | `status-cluster.yml` |
| 00-clean-cluster | `clean-all.yml` |

## ایرادهای معماری و رفع آن‌ها

| ایراد در v1 | رفع در v2 |
|---|---|
| IP/نام نودها، پورت‌ها، مسیرها و نسخه‌ها در ده‌ها جا hard-code بود | یک Inventory + group_vars؛ همه‌چیز مشتق می‌شود |
| هر ماشین با چند Alias تعریف می‌شد؛ `hosts: all` چندبار روی یک ماشین اجرا می‌شد | هر ماشین یک‌بار؛ نقش = عضویت در گروه |
| 07 دوباره NameNode را Format می‌کرد (حذف داده) | Format فقط اگر `current/VERSION` نباشد؛ re-format فقط با دو سوییچ صریح |
| ZooKeeper بعد از HDFS نصب می‌شد و Format دوبار انجام می‌شد | ZooKeeper اول؛ یک مسیر راه‌اندازی HA |
| Playbook های Clean بدون تأیید حذف می‌کردند | `confirm_destroy_data=yes` اجباری |
| `10-configure-hive` همیشه DB را Drop می‌کرد | فقط اگر Schema وجود نداشته باشد ساخته می‌شود (`schematool -info`) |
| client `mysql` روی Control Node لازم بود؛ رمز root در /tmp | دستورها روی خود نودهای MySQL با `/root/.my.cnf` (0600) |
| `root@%` و کاربر Hive از هر IP | root فقط local؛ کاربر Hive فقط از IP سرورهای Hive |
| `mysql0` ناموجود در 10-drop-metastore | کشف خودکار PRIMARY از خود Group |
| رمز Hive در دو جا متفاوت | یک مقدار در `secrets.yml` |
| کلید SSH ساخته نمی‌شد (sshfence ناکار) | کلید PEM یک‌بار روی Control Node ساخته و توزیع می‌شود (`-m PEM` برای JSch) |
| `fencing = shell(/bin/true)` یا `sshfence` تکراری | `sshfence` سپس `shell(/bin/true)` به‌صورت لیست |
| `ha.zookeeper.quorum`/fencing دوبار با `blockinfile` | همه در قالب‌ها (بدون blockinfile/lineinfile روی XML) |
| دو Java هم‌زمان در `/etc/profile.d` و ناهماهنگی | یک `JAVA_HOME` برای Hadoop؛ Kafka با Java 17 و wrapper `kafka-cli` |
| unit ها: `kafka.service` و بعضی فایل‌ها با CRLF | همه‌ی فایل‌ها LF/UTF-8 |
| `/var/run/*` پس از reboot پاک می‌شد | `tmpfiles.d` |
| پورت JMX تکراری (7074 برای چند سرویس) و Ranger | پورت یکتا برای هر daemon؛ Ranger حذف |
| JMX با ویرایش hadoop-env.sh و ری‌استارت همه | `-javaagent` در Environment خود unit (CLI را تحت تأثیر قرار نمی‌دهد) |
| Hive با دو روش (systemd و nohup) | فقط systemd |
| Hive + Hadoop 3.3: ناسازگاری Guava | جایگزینی خودکار guava هماهنگ با Hadoop |
| YARN RM HA بدون ذخیره‌ی State | `ZKRMStateStore` + `recovery.enabled` ، `vmem-check` خاموش |
| `dfs.replication` ثابت 3 | `min(3, تعداد DataNode)` |
| منابع ثابت (8192/2048) | `resource_mode: auto` بر اساس RAM هر نود |
| نام Spark tarball سخت‌کد؛ نام پوشه‌ی استخراج‌شده سخت‌کد | `--strip-components=1` برای همه‌ی tarball ها |
| نصب RPM با dnf و ریپازیتوری (در Air-gap کند/ناموفق) | `--disablerepo='*'` ؛ همه‌ی RPM های پوشه با هم |
| مراحل بی‌فایده | حذف: UseDNS، کشتن چندباره‌ی پردازه‌ها، کپی تکراری tar، `wheel` برای hadoop، تنظیم hostname |
| `ansible.posix.firewalld` | `firewall-cmd` (بدون Collection) |

> یادآوری: در سند Word قبلی ادعا شده بود قالب‌های XML تگ `<n>` دارند؛ این **درست نبود**. فایل‌های اصلی `<name>` داشتند.

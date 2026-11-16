# عملیات روزمره

## نام سرویس‌های systemd
`hadoop-{journalnode,namenode,zkfc,datanode,resourcemanager,nodemanager,historyserver}` ،
`zookeeper` ، `mysqld` ، `hive-metastore` ، `hive-server2` ، `spark-history-server` ، `kafka`.

## دستورهای پرکاربرد
```bash
make status
journalctl -u hadoop-namenode -f
sudo -u hadoop hdfs haadmin -getAllServiceState
sudo -u hadoop hdfs dfsadmin -report
sudo -u hadoop yarn node -list
mysql -e "SELECT MEMBER_HOST,MEMBER_STATE,MEMBER_ROLE FROM performance_schema.replication_group_members"
beeline -u jdbc:hive2://<hive-host>:10000 -n hadoop -e "show databases"
kafka-cli kafka-topics.sh --bootstrap-server <broker>:9092 --list
```

## افزودن DataNode/NodeManager
نود را در `all.hosts` و گروه‌های `datanodes` و `nodemanagers` اضافه کنید، سپس:
```bash
ansible-playbook playbooks/system/initialize.yml --limit <node>
ansible-playbook playbooks/hadoop/3.3.6/install.yml --limit <node>
ansible-playbook playbooks/hadoop/3.3.6/start.yml --limit <node>
```

## تست Failover
```bash
sudo systemctl stop hadoop-namenode        # روی NameNode فعال
sudo -u hadoop hdfs haadmin -getAllServiceState   # ~۱۵–۳۰ ثانیه بعد، دیگری active است
```

## تغییر MySQL Primary
بعد از Failover در MySQL: `playbooks/hive/3.1.3/refresh-metastore-endpoint.yml` (یا از MySQL Router استفاده کنید).

## عیب‌یابی سریع
| نشانه | علت/راه‌حل |
|---|---|
| Playbook با «Package not found» متوقف شد | `offline_packages/MANIFEST.md` را با پوشه‌ها مقایسه کنید |
| `not initialised` | `system/initialize.yml` اجرا نشده |
| Hive: `NoSuchMethodError … Preconditions` | `hive_replace_guava: true` (پیش‌فرض) |
| MySQL Group Replication: خطای 3092 | ابتدا error log، تنظیمات GR و SELinux port را بررسی کنید؛ برای رفع خطای عضویت، داده‌ها را پاک نکنید. اگر همه‌ی اعضا خاموش بوده‌اند، فقط پس از مقایسه‌ی `GTID_EXECUTED` از `bootstrap-after-outage.yml` با `bootstrap_host` استفاده کنید. |
| NameNode بالا نمی‌آید بعد از تغییر ZK | `hdfs zkfc -formatZK` فقط در bootstrap-ha انجام می‌شود؛ znode را بررسی کنید |

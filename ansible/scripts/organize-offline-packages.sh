#!/usr/bin/env bash
# Moves a flat folder of downloaded packages into the versioned offline_packages layout.
#   usage: scripts/organize-offline-packages.sh <source-dir> [--copy]
set -euo pipefail
SRC="${1:?usage: $0 <source-dir> [--copy]}"
MODE="${2:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)/offline_packages"
op() { if [ "$MODE" = "--copy" ]; then cp -v "$1" "$2"; else mv -v "$1" "$2"; fi; }
place() {  # <glob-in-src> <target-subdir>
  local found=0
  for f in "$SRC"/$1; do
    [ -e "$f" ] || continue; found=1
    mkdir -p "$ROOT/$2"; op "$f" "$ROOT/$2/"
  done
  [ $found -eq 1 ] || echo "  (not found: $1)"
}
place 'OpenJDK8U-jdk_x64_linux_hotspot_8u492b09.tar.gz' java/openjdk-8u492-b09
place 'jdk11.tar.gz'                                    java/openjdk-11
place 'java-17-openjdk*.rpm'                            java/openjdk-17.0.20.1.1
place 'java17/*.rpm'                                    java/openjdk-17.0.20.1.1
place 'hadoop-3.3.6.tar.gz'                             hadoop/hadoop-3.3.6
place 'apache-zookeeper-3.8.4-bin.tar.gz'               zookeeper/zookeeper-3.8.4
place 'apache-hive-3.1.3-bin.tar.gz'                    hive/hive-3.1.3
place 'mysql-connector-java-8.0.28.jar'                 mysql/mysql-connector-j-8.0.28
place 'mysql-offline/*.rpm'                             mysql/mysql-server-8.0.42
place 'mysql-community-*.rpm'                           mysql/mysql-server-8.0.42
place 'mysql-selinux*.rpm'                              mysql/mysql-server-8.0.42
place 'mecab*.rpm'                                      mysql/mysql-server-8.0.42
place 'protobuf-lite*.rpm'                              mysql/mysql-server-8.0.42
place 'spark-3.5.4-bin-hadoop3*.tgz'                    spark/spark-3.5.4
place 'kafka_2.13-4.0.0.tgz'                            kafka/kafka-4.0.0
place 'jmx_prometheus_javaagent-1.1.0.jar'              monitoring/jmx-exporter-1.1.0
# Spark: accept the old name "…-bin-hadoop3.3.tgz"
for f in "$ROOT"/spark/spark-3.5.4/*hadoop3.3.tgz; do
  [ -e "$f" ] && mv -v "$f" "${f/hadoop3.3.tgz/hadoop3.tgz}"
done
echo "Done. Check with: make preflight"

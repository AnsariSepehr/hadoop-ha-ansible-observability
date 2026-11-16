# Spark on YARN

[← Documentation index](../README.md)

Spark 3.5.4 is installed on node1 and node2 as a client. Jobs run as YARN containers, so Spark has no cluster of its own to keep alive. The History Server on node1 shows finished jobs.

## What the role does

1.  Installs Spark and writes spark-env.sh and spark-defaults.conf.

2.  Copies hive-site.xml so Spark SQL uses the same metastore as Hive.

3.  Creates the HDFS directories for event logs and the history store.

4.  Installs the History Server unit on node1 and runs a smoke job.

## Sizing

| Setting            | Value           | Rule                                                  |
|--------------------|-----------------|-------------------------------------------------------|
| Executors          | 2               | spark_executor_instances                              |
| Cores per executor | 1               | spark_executor_cores                                  |
| Executor container | At most 4096 MB | The smaller of the YARN scheduler maximum and the cap |
| Executor overhead  | At least 384 MB | 10 percent of the container, whichever is larger      |
| Driver memory      | 1024 MB         | spark_driver_memory_mb                                |

The container size must stay under yarn_sched_max_mb, or YARN rejects the request. The defaults enforce this.

## Verify

spark-submit --master yarn --deploy-mode cluster --class org.apache.spark.examples.SparkPi \\  
\$SPARK_HOME/examples/jars/spark-examples\_\*.jar 10  
\# History UI: http://\<NODE1_IP\>:18080

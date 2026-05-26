#!/usr/bin/env bash
# 下载运行所需的依赖 jar 包(Spark / Delta Lake / Hadoop-AWS / PostgreSQL 驱动)。
# 这些包体积较大,不放进 Git 仓库,改为运行时下载。
# 用法:bash download-jars.sh

set -euo pipefail

MAVEN="https://repo1.maven.org/maven2"
JARS_DIR="spark/jars"
HIVE_LIB_DIR="hive/lib"

mkdir -p "$JARS_DIR" "$HIVE_LIB_DIR"

download() {
  local url="$1" dest="$2"
  if [ -f "$dest" ]; then
    echo "✓ 已存在,跳过:$dest"
  else
    echo "↓ 下载:$dest"
    curl -fL --retry 3 "$url" -o "$dest"
  fi
}

echo "== 下载 Spark 所需 jar 到 $JARS_DIR =="
download "$MAVEN/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar" "$JARS_DIR/aws-java-sdk-bundle-1.12.262.jar"
download "$MAVEN/io/delta/delta-core_2.12/2.4.0/delta-core_2.12-2.4.0.jar"                     "$JARS_DIR/delta-core_2.12-2.4.0.jar"
download "$MAVEN/io/delta/delta-storage/2.4.0/delta-storage-2.4.0.jar"                          "$JARS_DIR/delta-storage-2.4.0.jar"
download "$MAVEN/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar"                       "$JARS_DIR/hadoop-aws-3.3.4.jar"
download "$MAVEN/org/postgresql/postgresql/42.7.2/postgresql-42.7.2.jar"                        "$JARS_DIR/postgresql-42.7.2.jar"

echo "== 下载 Hive 所需 jar 到 $HIVE_LIB_DIR =="
download "$MAVEN/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar"                       "$HIVE_LIB_DIR/hadoop-aws-3.3.4.jar"

echo ""
echo "✅ 全部依赖 jar 准备完成,可以执行 docker compose up -d 了。"

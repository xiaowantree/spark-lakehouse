# Spark Lakehouse(本地数据湖栈)

一套用 **Docker Compose** 一键拉起的本地数据湖环境,包含对象存储、元数据服务、计算引擎和 SQL 网关,适合本地开发与学习。

## 技术栈

| 组件 | 作用 | 镜像 |
|------|------|------|
| **MinIO** | S3 兼容对象存储(数据湖底座) | `minio/minio` |
| **PostgreSQL** | Hive Metastore 的后端数据库 | `postgres:14-alpine` |
| **Hive Metastore** | 表的元数据管理 | `apache/hive:3.1.3` |
| **Spark**(Master + Worker) | 分布式计算引擎 | `apache/spark:3.4.1` |
| **Kyuubi** | 多租户 SQL 网关(JDBC/Thrift 入口) | `apache/kyuubi:1.8.0-spark` |
| **Delta Lake** | 表格式(ACID 事务) | jar 依赖 |

## 前置要求

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)(含 Docker Compose)
- `bash` 和 `curl`(用于下载依赖 jar)
- 建议预留 **8GB 以上内存** 给 Docker

> **关于 CPU 架构**:本项目的 `docker-compose.yml` 默认按 **Apple Silicon(arm64)** 配置,其中 Hive 和 Kyuubi 通过 `linux/amd64` 仿真运行。如果你用的是 **Intel/AMD(x86_64)** 电脑,需要把 `docker-compose.yml` 里各服务的 `platform:` 字段改成 `linux/amd64`(或整行删除让 Docker 自动选择)。

## 快速开始

```bash
# 1. 克隆仓库
git clone <本仓库地址>
cd spark-lakehouse

# 2. 下载依赖 jar(体积较大,未放进仓库)
bash download-jars.sh

# 3. 启动全部服务
docker compose up -d

# 4. 查看运行状态
docker compose ps
```

首次启动会拉取镜像,耗时取决于网速。等所有容器状态为 `running` / `healthy` 即可使用。

## 访问入口

| 服务 | 地址 | 说明 |
|------|------|------|
| MinIO 控制台 | http://localhost:9001 | 账号 `admin` / 密码 `admin12345` |
| MinIO API(S3) | http://localhost:9000 | 程序访问端点 |
| Spark Master UI | http://localhost:8080 | 集群状态 |
| Spark Worker UI | http://localhost:8081 | Worker 状态 |
| Kyuubi(JDBC) | `jdbc:hive2://localhost:10009` | 用 beeline / DBeaver 连 |
| Hive Metastore | `thrift://localhost:9083` | 元数据服务 |

启动后会自动创建一个名为 `wba` 的 MinIO 桶。

## 连接示例(用 beeline 连 Kyuubi 跑 SQL)

```bash
docker exec -it kyuubi /opt/kyuubi/bin/beeline -u 'jdbc:hive2://localhost:10009'
```

## 停止与清理

```bash
# 停止服务(保留数据)
docker compose down

# 停止并删除数据卷(彻底清空 MinIO/Postgres 数据)
docker compose down -v
```

## 目录结构

```
.
├── docker-compose.yml      # 服务编排
├── download-jars.sh        # 依赖 jar 下载脚本
├── spark-config/           # Spark 配置(spark-defaults.conf、hive-site.xml)
├── hive-config/            # Hive Metastore 配置
├── kyuubi-config/          # Kyuubi 配置
├── spark/jars/             # Spark 依赖 jar(由脚本下载,未入库)
├── hive/lib/               # Hive 依赖 jar(由脚本下载,未入库)
├── minio-data/             # MinIO 数据(运行时生成,未入库)
├── pg-data/                # PostgreSQL 数据(运行时生成,未入库)
└── jobs/                   # 放置你的 Spark 作业脚本
```

## 说明

- `minio-data/`、`pg-data/`、`warehouse/` 是运行时数据,已通过 `.gitignore` 排除,不会上传。
- 默认账号密码(`admin` 等)仅供本地开发,**请勿用于生产环境**。

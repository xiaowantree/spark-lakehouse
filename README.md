# Spark Lakehouse(本地数据湖栈)

一套用 **Docker Compose** 一键拉起的本地数据湖环境,包含对象存储、元数据服务、计算引擎和 SQL 网关,适合本地开发与学习。

数据用 **Delta Lake** 格式存放在 **MinIO**(S3 兼容)里,元数据由 **Hive Metastore** 管理,计算交给 **Spark**,对外通过 **Kyuubi** 提供标准 SQL(JDBC)入口——你可以直接用 DBeaver 连上去写 SQL。

## 技术栈

| 组件 | 作用 | 镜像 |
|------|------|------|
| **MinIO** | S3 兼容对象存储(数据湖底座) | `minio/minio` |
| **PostgreSQL** | Hive Metastore 的后端数据库 | `postgres:14-alpine` |
| **Hive Metastore** | 表的元数据管理 | `apache/hive:3.1.3` |
| **Spark**(Master + Worker) | 分布式计算引擎 | `apache/spark:3.4.1` |
| **Kyuubi** | SQL 网关(JDBC/Thrift 入口) | `apache/kyuubi:1.8.0-spark` |
| **Delta Lake** | 表格式(ACID 事务) | jar 依赖,见下文 |

## 前置要求

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)(自带 Docker Compose),建议给 Docker 分配 **8GB 以上内存**
- `bash` + `curl`(用于下载依赖 jar)
- 可选:[DBeaver](https://dbeaver.io/)(图形化 SQL 客户端,用来连 Kyuubi 写 SQL)

> **CPU 架构提示**:`docker-compose.yml` 默认按 **Apple Silicon(arm64)** 配置,Hive 和 Kyuubi 通过 `linux/amd64` 仿真运行。如果你是 **Intel/AMD(x86_64)** 电脑,请把 `docker-compose.yml` 里各服务的 `platform:` 字段统一改成 `linux/amd64`,或整行删除让 Docker 自动选择。

---

## 快速开始

### 第 1 步:获取代码

```bash
git clone https://github.com/xiaowantree/spark-lakehouse.git
cd spark-lakehouse
```

### 第 2 步:下载依赖 jar

这些 jar 体积大(其中一个 268MB),没有放进仓库,需要先下载到位:

```bash
bash download-jars.sh
```

脚本会把 jar 下载到 `spark/jars/` 和 `hive/lib/`。具体下了哪些见 [依赖 jar 清单](#依赖-jar-清单)。

### 第 3 步:启动全部服务

```bash
docker compose up -d
```

首次启动会拉取镜像,耗时取决于网速。启动后查看状态:

```bash
docker compose ps
```

等所有容器显示 `running`(或 `healthy`)即就绪。系统会自动在 MinIO 里创建一个名为 `wba` 的桶。

### 第 4 步:验证

浏览器打开 **http://localhost:8080**,能看到 Spark Master 页面、且有 1 个 Worker 注册,就说明集群起来了。

### 停止与清理

```bash
docker compose down      # 停止服务(保留数据)
docker compose down -v   # 停止并删除数据卷(彻底清空)
```

---

## 用 DBeaver 连接(写 SQL)

Kyuubi 暴露的是标准 HiveServer2 接口,用 DBeaver 内置的 **Apache Hive** 驱动即可连接,**无需用户名密码**。

1. 打开 DBeaver → **数据库** → **新建数据库连接**
2. 搜索并选择 **Apache Hive** → 下一步
3. 填写连接信息:

   | 字段 | 值 |
   |------|-----|
   | Host(主机) | `localhost` |
   | Port(端口) | `10009` |
   | Database(数据库) | `default` |
   | Username / Password | **留空**(本栈未开认证) |

4. 首次连接 DBeaver 会提示下载 Hive 驱动,点 **下载/Download** 即可
5. 点 **测试连接(Test Connection)** → 成功后点 **完成**

> 也可以直接用 JDBC 串:`jdbc:hive2://localhost:10009/default`

### 命令行连接(可选)

不想装 DBeaver,可以直接进容器用 beeline:

```bash
docker exec -it kyuubi /opt/kyuubi/bin/beeline -u 'jdbc:hive2://localhost:10009/default'
```

连上后即可建表写数据,例如:

```sql
CREATE TABLE demo (id INT, name STRING) USING delta;
INSERT INTO demo VALUES (1, 'hello'), (2, 'world');
SELECT * FROM demo;
```

---

## 各服务访问入口

| 服务 | 地址 | 说明 |
|------|------|------|
| MinIO 控制台 | http://localhost:9001 | 账号 `admin` / 密码 `admin12345` |
| MinIO API(S3) | http://localhost:9000 | 程序访问端点 |
| Spark Master UI | http://localhost:8080 | 集群状态 |
| Spark Worker UI | http://localhost:8081 | Worker 状态 |
| Kyuubi(JDBC/SQL) | `jdbc:hive2://localhost:10009` | DBeaver / beeline 连接 |
| Hive Metastore | `thrift://localhost:9083` | 元数据服务 |

---

## 依赖 jar 清单

运行 `bash download-jars.sh` 会自动下载以下 jar(均来自 Maven 中央仓库):

**下载到 `spark/jars/`:**

| jar 文件 | 版本 | 用途 |
|----------|------|------|
| `hadoop-aws-3.3.4.jar` | 3.3.4 | 让 Spark 通过 S3A 协议访问 MinIO |
| `aws-java-sdk-bundle-1.12.262.jar` | 1.12.262 | AWS SDK(hadoop-aws 的依赖,**268MB**) |
| `delta-core_2.12-2.4.0.jar` | 2.4.0 | Delta Lake 核心引擎 |
| `delta-storage-2.4.0.jar` | 2.4.0 | Delta Lake 存储层 |
| `postgresql-42.7.2.jar` | 42.7.2 | Hive Metastore 连接 PostgreSQL 的 JDBC 驱动 |

**下载到 `hive/lib/`:**

| jar 文件 | 版本 | 用途 |
|----------|------|------|
| `hadoop-aws-3.3.4.jar` | 3.3.4 | 让 Hive Metastore 也能识别 S3A 路径 |

> 版本与 Spark `3.4.1` / Scala `2.12` / Hadoop `3.3.4` 匹配,自行升级时请保持兼容。

---

## 目录结构

```
.
├── docker-compose.yml      # 服务编排
├── download-jars.sh        # 依赖 jar 一键下载脚本
├── spark-config/           # Spark 配置(spark-defaults.conf、hive-site.xml)
├── hive-config/            # Hive Metastore 配置
├── kyuubi-config/          # Kyuubi 配置(kyuubi-defaults.conf)
├── spark/jars/             # Spark 依赖 jar(由脚本下载,未入库)
├── hive/lib/               # Hive 依赖 jar(由脚本下载,未入库)
├── minio-data/             # MinIO 数据(运行时生成,未入库)
├── pg-data/                # PostgreSQL 数据(运行时生成,未入库)
└── jobs/                   # 放置你的 Spark 作业脚本
```

## 说明

- `minio-data/`、`pg-data/`、`warehouse/` 是运行时数据,已通过 `.gitignore` 排除,不会上传。
- 默认账号密码(`admin` 等)仅供本地开发,**请勿用于生产环境**。

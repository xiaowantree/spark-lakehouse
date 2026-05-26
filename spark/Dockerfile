FROM eclipse-temurin:17-jre-jammy
ARG SPARK_VERSION=3.5.2
ARG HADOOP_FLAVOR=hadoop3
ARG SPARK_TGZ_URL=https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-${HADOOP_FLAVOR}.tgz
RUN apt-get update && apt-get install -y --no-install-recommends curl wget ca-certificates python3 python3-pip procps && rm -rf /var/lib/apt/lists/*
WORKDIR /opt
RUN wget -q ${SPARK_TGZ_URL} -O spark.tgz && tar -xzf spark.tgz && rm spark.tgz && ln -s spark-${SPARK_VERSION}-bin-${HADOOP_FLAVOR} spark
ENV SPARK_HOME=/opt/spark
ENV PATH=$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH
# 预置 Delta & S3 依赖
RUN mkdir -p $SPARK_HOME/jars-extra && \
    wget -q https://repo1.maven.org/maven2/io/delta/delta-core_2.12/2.4.0/delta-core_2.12-2.4.0.jar -P $SPARK_HOME/jars-extra && \
    wget -q https://repo1.maven.org/maven2/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar -P $SPARK_HOME/jars-extra && \
    wget -q https://repo1.maven.org/maven2/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar -P $SPARK_HOME/jars-extra
RUN mkdir -p $SPARK_HOME/conf && \
    bash -lc 'echo "spark.jars=/opt/spark/jars-extra/delta-core_2.12-2.4.0.jar,/opt/spark/jars-extra/hadoop-aws-3.3.4.jar,/opt/spark/jars-extra/aws-java-sdk-bundle-1.12.262.jar" >> $SPARK_HOME/conf/spark-defaults.conf'
EXPOSE 7077 8080 8081

# https://github.com/njmittet/alpine-activemq/blob/master/Dockerfile
FROM alpine:3.20

ENV OPENJDK_VERSION=11
# renovate: datasource=custom.activemq depName=apache/activemq extractVersion=^(?<version>.*)/$
ENV ACTIVEMQ_VERSION=5.18.5

# which ports...?
#EXPOSE 1883 5672 8161 61613 61614 61616
EXPOSE 8161 61613 61616


# Update packages and install tools
RUN apk add --no-cache \
    curl \
    openjdk${OPENJDK_VERSION}-jre-headless

# NOTE: need to set JAVA_HOME, otherwise it won't be able to find the javadoc binary
ENV JAVA_HOME="/usr/lib/jvm/java-${OPENJDK_VERSION}-openjdk"
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Run non privileged
RUN addgroup --system activemq \
  && adduser --system activemq activemq

RUN curl --silent --fail -OL http://archive.apache.org/dist/activemq/${ACTIVEMQ_VERSION}/apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz \
  && tar -zxvf apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz -C /opt \
  && ln -s /opt/apache-activemq-${ACTIVEMQ_VERSION} /opt/activemq \
  && sed -i 's/127.0.0.1/0.0.0.0/g' /opt/activemq/conf/jetty.xml \
  && chown -R activemq:activemq /opt/apache-activemq-${ACTIVEMQ_VERSION} /opt/activemq \
  && rm /apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz

COPY --chown=activemq:activemq activemq.xml /opt/activemq/conf/

# renovate: datasource=github-release-attachments depName=prometheus/jmx_exporter
ARG JMX_EXPORTER_VERSION=1.4.0
ARG JMX_EXPORTER_DIGEST=sha256:db1492e95a7ee95cd5e0a969875c0d4f0ef6413148d750351a41cc71d775f59a
WORKDIR /jmx
ADD \
  --link \
  --chmod=644 \
  --checksum=$JMX_EXPORTER_DIGEST \
  https://github.com/prometheus/jmx_exporter/releases/download/$JMX_EXPORTER_VERSION/jmx_prometheus_javaagent-$JMX_EXPORTER_VERSION.jar jmx_prometheus_javaagent.jar
COPY --chmod=644 jmx.yml ./

ENV JMX_OPT="-javaagent:/jmx/jmx_prometheus_javaagent.jar=3001:/jmx/jmx.yml"
ENV ACTIVEMQ_OPTS="${JMX_OPT}"

USER activemq

WORKDIR /opt/activemq

COPY healthcheck.sh /bin/
HEALTHCHECK --interval=10s --timeout=10s --start-period=5s --retries=3 \
  CMD [ "/bin/healthcheck.sh" ]

CMD ["bin/activemq", "console"]

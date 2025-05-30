ARG ACTIVEMQ_UID=100
ARG ACTIVEMQ_GID=101
# renovate: datasource=custom.activemq depName=apache/activemq extractVersion=^(?<version>.*)/$
ARG ACTIVEMQ_VERSION=5.18.5
ARG BASE_IMAGE=alpine:3.20
ARG BUILD_DIR=/build

FROM $BASE_IMAGE AS acquire

ARG ACTIVEMQ_UID
ARG ACTIVEMQ_GID
ARG ACTIVEMQ_VERSION
ARG BUILD_DIR

ADD --link --chown=$ACTIVEMQ_UID:$ACTIVEMQ_GID http://archive.apache.org/dist/activemq/${ACTIVEMQ_VERSION}/apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz $BUILD_DIR/

# https://github.com/njmittet/alpine-activemq/blob/master/Dockerfile
FROM $BASE_IMAGE

ENV OPENJDK_VERSION=11
ARG ACTIVEMQ_VERSION
ENV ACTIVEMQ_VERSION=$ACTIVEMQ_VERSION

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

ARG ACTIVEMQ_UID
ARG ACTIVEMQ_GID

# Run non privileged
RUN addgroup --system -g $ACTIVEMQ_GID activemq \
  && adduser --system -u $ACTIVEMQ_UID activemq activemq

USER activemq

ARG BUILD_DIR
WORKDIR /opt/activemq
RUN \
  --mount=type=bind,target=$BUILD_DIR,source=$BUILD_DIR,from=acquire \
<<EOS
set -e
tar -zxvf $BUILD_DIR/apache-activemq-${ACTIVEMQ_VERSION}-bin.tar.gz --strip-components 1
sed -i 's/127.0.0.1/0.0.0.0/g' conf/jetty.xml
EOS

COPY --chown=$ACTIVEMQ_UID:$ACTIVEMQ_GID activemq.xml conf/

COPY healthcheck.sh /bin/
HEALTHCHECK --interval=10s --timeout=10s --start-period=5s --retries=3 \
  CMD [ "/bin/healthcheck.sh" ]

CMD ["bin/activemq", "console"]

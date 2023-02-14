# https://github.com/njmittet/alpine-activemq/blob/master/Dockerfile
FROM alpine:3.14

ENV OPENJDK_VERSION=11
ENV ACTIVEMQ_VERSION=5.16.2

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

USER activemq

WORKDIR /opt/activemq

CMD ["bin/activemq", "console"]

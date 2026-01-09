#!/bin/sh

export ACTIVEMQ_OPTS="$ACTIVEMQ_OPTS -javaagent:/jmx/jmx_prometheus_javaagent.jar=3001:/jmx/jmx.yml"
exec bin/activemq console

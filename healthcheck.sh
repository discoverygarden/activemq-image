#!/bin/sh

# Do not run jmx_exporter in the healthcheck
export ACTIVEMQ_OPTS="${ACTIVEMQ_OPTS/"$JMX_OPT"}"
bin/activemq query --objname type=Broker,brokerName=*,service=Health | grep -qE '^CurrentStatus *= *Good$'


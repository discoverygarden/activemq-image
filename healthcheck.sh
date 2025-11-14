#!/bin/sh

# set -x
export ACTIVEMQ_OPTS="${ACTIVEMQ_OPTS/"$JMX_OPT"}"
bin/activemq query --objname type=Broker,brokerName=*,service=Health | grep -qE '^CurrentStatus *= *Good$'


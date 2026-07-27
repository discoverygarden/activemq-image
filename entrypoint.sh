#!/bin/sh

export ACTIVEMQ_OPTS="$ACTIVEMQ_OPTS $JMX_OPT"
exec bin/activemq console

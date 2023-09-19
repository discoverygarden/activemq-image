#!/bin/sh

/opt/activemq/bin/activemq query --objname type=Broker,brokerName=*,service=Health | grep Good


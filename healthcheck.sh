#!/bin/sh

bin/activemq query --objname type=Broker,brokerName=*,service=Health | grep -qE '^CurrentStatus *= *Good$'


#!/usr/bin/env bash

. ./env.sh

oc login https://${IP}:8443 -u $USER

oc delete project $DEV_PROJECT
oc delete project $TEST_PROJECT
oc delete project $PROD_PROJECT



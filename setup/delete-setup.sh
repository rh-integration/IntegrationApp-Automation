#!/usr/bin/env bash

. ./env.sh


oc delete project $DEV_PROJECT
oc delete project $TEST_PROJECT
oc delete project $PROD_PROJECT



#!/usr/bin/env bash

. ./env.sh 

oc delete project $DEV_PROJECT
oc new-project $DEV_PROJECT 2> /dev/null
while [ $? \> 0 ]; do
    sleep 1
    printf "."
    oc new-project $DEV_PROJECT 2> /dev/null
done

oc new-app jenkins-persistent

echo "Setup the surrounding softwate and environment"
echo
echo "Start up MySQL for database access"

oc new-app mysql-ephemeral --param=MYSQL_PASSWORD=password --param=MYSQL_USER=dbuser --param=MYSQL_DATABASE=sampledb

echo "Start up Broker"
oc import-image amq62-openshift --from=registry.access.redhat.com/jboss-amq-6/amq62-openshift --confirm
oc new-app -f projecttemplates/amq62-openshift.json --param=MQ_USERNAME=admin --param=MQ_PASSWORD=admin --param=IMAGE_STREAM_NAMESPACE=$DEV_PROJECT

echo "import fisuser-service pipeline"
oc new-app -f fisuser-service/src/main/resources/pipeline-app-build.yml -p IMAGE_NAMESPACE=$DEV_PROJECT -p DEV_PROJECT=$DEV_PROJECT -p TEST_PROJECT=$TEST_PROJECT -p PROD_PROJECT=$PROD_PROJECT 

echo "import maingateway-service pipeline"
oc new-app -f maingateway-service/src/main/resources/pipeline-app-build.yml -p IMAGE_NAMESPACE=$DEV_PROJECT -p DEV_PROJECT=$DEV_PROJECT -p TEST_PROJECT=$TEST_PROJECT -p PROD_PROJECT=$PROD_PROJECT

echo "import nodejsalert-ui pipeline"
oc new-app -f nodejsalert-ui/resources/pipeline-app-build.yml -p IMAGE_NAMESPACE=$DEV_PROJECT -p DEV_PROJECT=$DEV_PROJECT -p TEST_PROJECT=$TEST_PROJECT -p PROD_PROJECT=$PROD_PROJECT

echo "import fisalert-service pipeline"
oc new-app -f fisalert-service/src/main/resources/pipeline-app-build.yml -p IMAGE_NAMESPACE=$DEV_PROJECT -p DEV_PROJECT=$DEV_PROJECT -p TEST_PROJECT=$TEST_PROJECT -p PROD_PROJECT=$PROD_PROJECT

echo "import integration-master-pipeline"
oc new-app -f pipelinetemplates/pipeline-aggregated-build.yml -p IMAGE_NAMESPACE=$DEV_PROJECT -p DEV_PROJECT=$DEV_PROJECT -p TEST_PROJECT=$TEST_PROJECT -p PROD_PROJECT=$PROD_PROJECT

echo "import 3scale API publishing pipeline"
oc new-app -f cicd-3scale/groovy-scripts/pipeline-template.yaml -p IMAGE_NAMESPACE=$DEV_PROJECT -p DEV_PROJECT=$DEV_PROJECT -p TEST_PROJECT=$TEST_PROJECT -p PROD_PROJECT=$PROD_PROJECT

oc delete project $TEST_PROJECT
oc new-project $TEST_PROJECT 2> /dev/null
while [ $? \> 0 ]; do
    sleep 1
    printf "."
    oc new-project $TEST_PROJECT 2> /dev/null
done


echo "Setup the surrounding softwate and environment"
echo
echo "Start up MySQL for database access"

oc new-app mysql-ephemeral --param=MYSQL_PASSWORD=password --param=MYSQL_USER=dbuser --param=MYSQL_DATABASE=sampledb

echo "Start up Broker"
oc import-image amq62-openshift --from=registry.access.redhat.com/jboss-amq-6/amq62-openshift --confirm
oc new-app -f projecttemplates/amq62-openshift.json --param=MQ_USERNAME=admin --param=MQ_PASSWORD=admin --param=IMAGE_STREAM_NAMESPACE=$TEST_PROJECT

oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:jenkins -n ${TEST_PROJECT}
oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:default -n ${TEST_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${TEST_PROJECT}:default -n ${DEV_PROJECT}
oc policy add-role-to-user view --serviceaccount=default -n ${DEV_PROJECT}

#this should be used in development/demo environment for testing purpose
oc delete project $PROD_PROJECT
oc new-project $PROD_PROJECT 2> /dev/null
while [ $? \> 0 ]; do
    sleep 1
    printf "."
    oc new-project $PROD_PROJECT 2> /dev/null
done


echo "Setup the surrounding softwate and environment"
echo
echo "Start up MySQL for database access"
oc project $PROD_PROJECT
oc new-app mysql-ephemeral --param=MYSQL_PASSWORD=password --param=MYSQL_USER=dbuser --param=MYSQL_DATABASE=sampledb

echo "Start up Broker"
oc import-image amq62-openshift --from=registry.access.redhat.com/jboss-amq-6/amq62-openshift --confirm
oc new-app -f projecttemplates/amq62-openshift.json --param=MQ_USERNAME=admin --param=MQ_PASSWORD=admin --param=IMAGE_STREAM_NAMESPACE=$PROD_PROJECT


oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:jenkins -n ${PROD_PROJECT}
oc policy add-role-to-user edit system:serviceaccount:${DEV_PROJECT}:default -n ${PROD_PROJECT}
oc policy add-role-to-user system:image-puller system:serviceaccount:${PROD_PROJECT}:default -n ${DEV_PROJECT}
oc policy add-role-to-user view --serviceaccount=default -n ${DEV_PROJECT}

oc project $DEV_PROJECT

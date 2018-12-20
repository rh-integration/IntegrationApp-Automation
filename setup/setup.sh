#!/usr/bin/env bash

. ./env.sh

oc login -u $USER

#oc delete project $CICD_PROJECT
oc new-project $CICD_PROJECT 2> /dev/null
while [ $? \> 0 ]; do
    sleep 1
    printf "."
    oc new-project $CICD_PROJECT 2> /dev/null
done

oc new-app jenkins-persistent

#oc delete project $DEV_PROJECT
oc new-project $DEV_PROJECT 2> /dev/null
while [ $? \> 0 ]; do
    sleep 1
    printf "."
    oc new-project $DEV_PROJECT 2> /dev/null
done


echo "Setup the surrounding softwate and environment"
echo
echo "Start up MySQL for database access"

oc create -f https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mysql-ephemeral-template.json
oc new-app --template=mysql-ephemeral --param=MYSQL_PASSWORD=password --param=MYSQL_USER=dbuser --param=MYSQL_DATABASE=sampledb

echo "Start up Broker"
oc import-image amq62-openshift --from=registry.access.redhat.com/jboss-amq-6/amq62-openshift --confirm
oc create -f projecttemplates/amq62-openshift.json
oc new-app --template=amq62-basic --param=MQ_USERNAME=admin --param=MQ_PASSWORD=admin --param=IMAGE_STREAM_NAMESPACE=$DEV_PROJECT

oc policy add-role-to-user edit system:serviceaccount:${CICD_PROJECT}:jenkins -n ${DEV_PROJECT}
oc policy add-role-to-user edit system:serviceaccount:${CICD_PROJECT}:default -n ${DEV_PROJECT}
oc policy add-role-to-user view --serviceaccount=default -n ${DEV_PROJECT}

#oc delete project $PROD_PROJECT
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
oc create -f https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/mysql-ephemeral-template.json
oc new-app --template=mysql-ephemeral --param=MYSQL_PASSWORD=password --param=MYSQL_USER=dbuser --param=MYSQL_DATABASE=sampledb

echo "Start up Broker"
oc import-image amq62-openshift --from=registry.access.redhat.com/jboss-amq-6/amq62-openshift --confirm
oc create -f projecttemplates/amq62-openshift.json
oc new-app --template=amq62-basic --param=MQ_USERNAME=admin --param=MQ_PASSWORD=admin --param=IMAGE_STREAM_NAMESPACE=$PROD_PROJECT

oc policy add-role-to-user edit system:serviceaccount:${CICD_PROJECT}:jenkins -n ${PROD_PROJECT}
oc policy add-role-to-user edit system:serviceaccount:${CICD_PROJECT}:default -n ${PROD_PROJECT}
oc policy add-role-to-user view --serviceaccount=default -n ${PROD_PROJECT}






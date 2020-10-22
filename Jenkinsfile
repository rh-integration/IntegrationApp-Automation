#!groovy
library identifier: '3scale-toolbox-jenkins@master',
        retriever: modernSCM([$class: 'GitSCMSource',
                              remote: 'https://github.com/rh-integration/3scale-toolbox-jenkins.git',
                              traits: [[$class: 'jenkins.plugins.git.traits.BranchDiscoveryTrait']]])

def service = null

pipeline {
    agent {
        node {
            label 'maven'
        }
    }
    parameters {
        string(defaultValue: 'notinuse', name: 'OPENSHIFT_HOST', description: 'open shift cluster url')
        string(defaultValue: 'notinuse', name: 'OPENSHIFT_TOKEN', description: 'open shift token')
        string(defaultValue: 'image-registry.openshift-image-registry.svc:5000', name: 'IMAGE_REGISTRY', description: 'open shift token')
        string(defaultValue: 'rh-dev', name: 'IMAGE_NAMESPACE', description: 'name space where image deployed')
        string(defaultValue: 'all', name: 'DEPLOY_MODULE', description: 'target module to work on')
        string(defaultValue: 'rh-dev', name: 'DEV_PROJECT', description: 'build or development project')
        string(defaultValue: 'rh-test', name: 'TEST_PROJECT', description: 'Test project')
        string(defaultValue: 'rh-prod', name: 'PROD_PROJECT', description: 'Production project')
        string(defaultValue: 'https://github.com/rh-integration/IntegrationApp-Automation.git', name: 'GIT_REPO', description: 'Git source')
        string(defaultValue: 'master', name: 'GIT_BRANCH', description: 'Git branch in the source git')
        string(defaultValue: 'dbuser', name: 'MYSQL_USER', description: 'My Sql user name')
        string(defaultValue: 'password', name: 'MYSQL_PWD', description: 'My Sql user password')
        booleanParam(defaultValue: false, name: 'SELECT_BUILD_MODULE', description: 'Select module to build (default: build all to dev and test)')
        booleanParam(defaultValue: false, name: 'SELECT_DEPLOY_TO_PROD', description: 'Approval to deploy to Production (default: no deployment to production)')
    }
    stages {
        stage('Wait for user to select module to build.') {
            when {
                expression {
                    params.SELECT_BUILD_MODULE == true
                }
            }
            steps {
                script {
                    try {
                        timeout(time: 180, unit: 'SECONDS') {
                            env.userSelModule = input(id: 'userInput', message: 'Please select which module to bulid?',
                                    parameters: [[$class     : 'ChoiceParameterDefinition', defaultValue: 'strDef',
                                                  description: 'describing choices', name: 'nameChoice', choices: "Gateway\nFisUser\nFisAlert\nUI\nAll"]
                                    ])
                        }
                    } catch (exception) {
                        env.userSelModule = 'All'
                    }

                    println("User selected module " + env.userSelModule);
                }
            }
        }
        stage('source from git') {
            steps {
                git url: params.GIT_REPO, branch: params.GIT_BRANCH
            }
        }

        stage('Build maingateway-service') {
            environment {
                serviceName = 'maingateway-service'
            }
            when {
                expression {
                    ((env.userSelModule == 'Gateway' || env.userSelModule == 'All' || params.SELECT_BUILD_MODULE == false)
                            && params.SELECT_DEPLOY_TO_PROD == false)
                }
            }
            steps {
                echo "Building.. ${serviceName} "
                build(env.serviceName)

                echo "Deploying ${serviceName} to ${DEV_PROJECT}"
                deploy(env.serviceName, params.DEV_PROJECT, params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, params.MYSQL_USER, params.MYSQL_PWD)

            }
        }
        stage('Build fuse-user-service') {
            environment {
                serviceName = 'fuse-user-service'
            }
            when {
                expression {
                    ((env.userSelModule == 'FisUser' || env.userSelModule == 'All' || params.SELECT_BUILD_MODULE == false)
                            && params.SELECT_DEPLOY_TO_PROD == false)
                }
            }
            steps {
                echo "Building.. ${serviceName} "
                build(env.serviceName)

                echo "Deploying ${serviceName} to ${DEV_PROJECT}"
                deploy(env.serviceName, params.DEV_PROJECT, params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, params.MYSQL_USER, params.MYSQL_PWD)
            }
        }
        stage('Build fuse-alert-service') {
            environment {
                serviceName = 'fuse-alert-service'
            }
            when {
                expression {
                    ((env.userSelModule == 'FisAlert' || env.userSelModule == 'All' || params.SELECT_BUILD_MODULE == false)
                            && params.SELECT_DEPLOY_TO_PROD == false)
                }
            }
            steps {
                echo "Building.. ${serviceName} "
                build(env.serviceName)

                echo "Deploying ${serviceName} to ${DEV_PROJECT}"
                deploy(env.serviceName, params.DEV_PROJECT, params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, params.MYSQL_USER, params.MYSQL_PWD)
            }
        }
        stage('Build nodejsalert-ui') {
            environment {
                serviceName = 'nodejsalert-ui'
            }
            when {
                expression {
                    ((env.userSelModule == 'UI' || env.userSelModule == 'All' || params.SELECT_BUILD_MODULE == false)
                            && params.SELECT_DEPLOY_TO_PROD == false)

                }
            }
            steps {
                echo "Building.. ${serviceName}"

                git url: params.GIT_REPO, branch: params.GIT_BRANCH
                script {


                    def templatePath = 'nodejsalert-ui/resources/nodejs.json'
                    openshift.withCluster() {
                        openshift.withProject() {

                            echo "delete everything created with template ..."
                            if (openshift.selector('dc', serviceName).exists()) {
                                openshift.selector('dc', serviceName).delete()
                                openshift.selector('svc', serviceName).delete()
                                openshift.selector('route', serviceName).delete()
                                openshift.selector('is', serviceName).delete()

                            }
                            if (openshift.selector("bc", serviceName).exists()) {
                                openshift.selector('bc', serviceName).delete()
                            }

                            if (openshift.selector("secrets", serviceName).exists()) {
                                openshift.selector("secrets", serviceName).delete()
                            }

                            echo "create a new application from the templatePath..."
                            openshift.newApp(templatePath)

                            echo "start Build  ..."
                            def builds = openshift.selector("bc", env.serviceName).related('builds')
                            builds.logs('-f')
                            builds.watch {
                                echo " ${builds.name()} has created builds: ${it.names()}"
                                return it.count() > 0
                            }
                            builds.untilEach(1) {
                                return (it.object().status.phase == "Complete")
                            }

                            echo "start Deployment ..."

                            def rm = openshift.selector("dc", env.serviceName).rollout()
                            openshift.selector("dc", env.serviceName).related('pods').untilEach(1) {
                                return (it.object().status.phase == "Running")
                            }
                        }
                    }
                }

            }
        }
        stage('Dev-Env smoke-test') {
            when {
                expression {
                    params.SELECT_DEPLOY_TO_PROD == false
                }
            }
            steps {
                script {

                    echo "Waiting for deployment to complete prior starting smoke testing"
                    sleep 120

                    retry(5) {

                        serviceName = 'fuse-user-service'
                        smokeTestOperation = 'cicd/users/profile/11111'
                        makeGetRequest("http://${serviceName}:8080/${smokeTestOperation}")

                        serviceName = 'fuse-alert-service'
                        smokeTestOperation = 'cicd/alerts'
                        body = ''' { "alertType": "ACCIDENT",  "firstName": "user1",  "date": "11/8/2019",  "phone": "78135955",  "email": "user1@abc.com",  "description": "test"} '''
                        makePostRequest("http://${serviceName}:8080/${smokeTestOperation}", body, 'POST')

                        serviceName = 'maingateway-service'
                        smokeTestOperation = 'cicd/maingateway/profile/11111?alertType=ACCIDENT'
                        makeGetRequest("http://${serviceName}:8080/${smokeTestOperation}")


                        serviceName = 'nodejsalert-ui'
                        makeGetRequest("http://${serviceName}:8080")
                    }
                }
            }
        }

        stage('Pushing to Test - maingateway') {
            environment {
                srcTag = 'latest'
                destTag = 'promoteTest'
            }
            when {
                expression {
                    ((env.userSelModule == 'Gateway' || env.userSelModule == 'All' || params.SELECT_BUILD_MODULE == false)
                            && params.SELECT_DEPLOY_TO_PROD == false)
                }
            }
            steps {
                echo "Deploy to ${TEST_PROJECT} "
                tagImage(params.IMAGE_NAMESPACE, params.TEST_PROJECT, 'maingateway-service', env.srcTag, env.destTag)
                promoteServiceSetup(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'maingateway-service', params.IMAGE_REGISTRY, params.IMAGE_NAMESPACE, env.destTag, params.TEST_PROJECT)
                promoteService(params.IMAGE_NAMESPACE, params.TEST_PROJECT, 'maingateway-service', env.srcTag, env.destTag)
            }
        }
        stage('Pushing to Test - fisuser') {
            environment {
                srcTag = 'latest'
                destTag = 'promoteTest'
            }
            when {
                expression {
                    ((env.userSelModule == 'FisUser' || env.userSelModule == 'All' || params.SELECT_BUILD_MODULE == false)
                            && params.SELECT_DEPLOY_TO_PROD == false)
                }
            }
            steps {
                echo "Deploy to ${TEST_PROJECT} "
                tagImage(params.IMAGE_NAMESPACE, params.TEST_PROJECT, 'fuse-user-service', env.srcTag, env.destTag)
                promoteServiceSetup(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'fuse-user-service', params.IMAGE_REGISTRY, params.IMAGE_NAMESPACE, env.destTag, params.TEST_PROJECT)
                setEnvForDBModule(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'fuse-user-service', params.TEST_PROJECT, params.MYSQL_USER, params.MYSQL_PWD)
                promoteService(params.IMAGE_NAMESPACE, params.TEST_PROJECT, 'fuse-user-service', env.srcTag, env.destTag)
            }
        }
        stage('Pushing to Test - fisalert') {
            environment {
                srcTag = 'latest'
                destTag = 'promoteTest'
            }
            when {
                expression {
                    ((env.userSelModule == 'FisAlert' || env.userSelModule == 'All' || params.SELECT_BUILD_MODULE == false)
                            && params.SELECT_DEPLOY_TO_PROD == false)
                }
            }
            steps {
                echo "Deploy to ${TEST_PROJECT} "
                tagImage(params.IMAGE_NAMESPACE, params.TEST_PROJECT, 'fuse-alert-service', env.srcTag, env.destTag)
                promoteServiceSetup(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'fuse-alert-service', params.IMAGE_REGISTRY, params.IMAGE_NAMESPACE, env.destTag, params.TEST_PROJECT)
                promoteService(params.IMAGE_NAMESPACE, params.TEST_PROJECT, 'fuse-alert-service', env.srcTag, env.destTag)
            }
        }
        stage('Pushing to Test - nodejsalert') {
            environment {
                srcTag = 'latest'
                destTag = 'promoteTest'
            }
            when {
                expression {
                    ((env.userSelModule == 'UI' || env.userSelModule == 'All' || params.SELECT_BUILD_MODULE == false)
                            && params.SELECT_DEPLOY_TO_PROD == false)
                }
            }
            steps {
                echo "Deploy to ${TEST_PROJECT} "
                tagImage(params.IMAGE_NAMESPACE, params.TEST_PROJECT, 'nodejsalert-ui', env.srcTag, env.destTag)
                promoteServiceSetup(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'nodejsalert-ui', params.IMAGE_REGISTRY, params.IMAGE_NAMESPACE, env.destTag, params.TEST_PROJECT)
                promoteService(params.IMAGE_NAMESPACE, params.TEST_PROJECT, 'nodejsalert-ui', env.srcTag, env.destTag)
            }
        }

        stage('Test-Env smoke-test') {
            when {
                expression {
                    params.SELECT_DEPLOY_TO_PROD == false
                }
            }
            steps {
                script {
                    echo "Waiting for deployment to complete prior starting smoke testing"
                    sleep 60

                    sh "oc project ${TEST_PROJECT}"
                    retry(5) {
                        serviceName = 'fuse-user-service'
                        smokeTestOperation = 'cicd/users/profile/11111'
                        makeGetRequest("http://${serviceName}:8080/${smokeTestOperation}")

                        serviceName = 'fuse-alert-service'
                        smokeTestOperation = 'cicd/alerts'
                        body = ''' { "alertType": "ACCIDENT",  "firstName": "user1",  "date": "11/8/2019",  "phone": "78135955",  "email": "user1@abc.com",  "description": "test"} '''
                        makePostRequest("http://${serviceName}:8080/${smokeTestOperation}", body, 'POST')

                        serviceName = 'maingateway-service'
                        smokeTestOperation = 'cicd/maingateway/profile/11111?alertType=ACCIDENT'
                        makeGetRequest("http://${serviceName}:8080/${smokeTestOperation}")


                        serviceName = 'nodejsalert-ui'
                        makeGetRequest("http://${serviceName}:8080")
                    }
                }
            }
        }

        stage('3scale Publish API to Test') {
            when {
                expression {
                    params.SELECT_DEPLOY_TO_PROD == false
                }
            }
            steps {
                script {

                    def envName = params.TEST_PROJECT
                    def app_name = 'maingateway-service'
                    def backend_service = sh(script: "oc get route ${app_name} -o jsonpath=\'{.spec.host}\' -n ${envName}", returnStdout: true)
                    def targetPort = sh(script: "oc get route ${app_name} -o jsonpath=\'{.spec.port.targetPort}\' -n ${envName}", returnStdout: true)
                    backend_service = "http://" + backend_service
                    println "${backend_service} "

                    echo "Prepare 3scale Configuration"
                    service = toolbox.prepareThreescaleService(
                            openapi: [filename: "cicd-3scale/3scaletoolbox/openapi-spec.json"],
                            environment: [baseSystemName                : params.API_BASE_SYSTEM_NAME,
                                          privateBaseUrl                : backend_service,
                                          privateBasePath               : "/cicd",
                                          environmentName               : envName,
                                          publicStagingWildcardDomain   : params.PUBLIC_STAGING_WILDCARD_DOMAIN != "" ? params.PUBLIC_STAGING_WILDCARD_DOMAIN : null,
                                          publicProductionWildcardDomain: params.PUBLIC_PRODUCTION_WILDCARD_DOMAIN != "" ? params.PUBLIC_PRODUCTION_WILDCARD_DOMAIN : null
                            ],
                            toolbox: [openshiftProject: params.DEV_PROJECT, destination: params.TARGET_INSTANCE,
                                      image           : params.TOOLBOX_IMAGE_REGISTRY,
                                      insecure        : params.DISABLE_TLS_VALIDATION == "yes",
                                      secretName      : params.SECRET_NAME],
                            service: [:],
                            applicationPlans: [
                                    [systemName: "plan1", name: "plan1", defaultPlan: true, costPerMonth: 100, setupFee: 10, trialPeriodDays: 5],
                                    [systemName: "silver", name: "Silver", costPerMonth: 100, setupFee: 10, trialPeriodDays: 5],
                                    [artefactFile: params.PLAN_YAML_FILE_PATH],
                            ],
                            applications: [
                                    [name: "my-test-app", description: "This is used for test environment", plan: "plan1", account: params.DEVELOPER_ACCOUNT_ID]

                            ]
                    )

                    echo "toolbox version = " + service.toolbox.getToolboxVersion()

                    echo "Import OpenAPI"
                    service.importOpenAPI()
                    echo "Service with system_name ${service.environment.targetSystemName} created !"

                    echo "Create an Application Plan"
                    service.applyApplicationPlans()

                    echo "Create an Application"
                    service.applyApplication()

                    echo "Run integration tests"

                    def proxy = service.readProxy("sandbox")
                    def sandbox_endpoint = proxy.sandbox_endpoint
                    retry(5) {
                        sh """set -e +x
                          curl -k -f -w "UserAlert: %{http_code}\n" -o /dev/null -s ${
                            sandbox_endpoint
                        }/cicd/maingateway/profile/11111?alertType=ACCIDENT"&api-key=${service.applications[0].userkey}"
                        """
                    }

                    echo "Promote to production"
                    service.promoteToProduction()

                }
            }
        }

        stage('Wait for user to select module to push to production.') {
            when {
                expression {
                    params.SELECT_DEPLOY_TO_PROD == true
                }
            }
            steps {
                script {
                    try {
                        timeout(time: 2, unit: 'HOURS') {
                            env.userProdApproval = input(id: 'userInput', message: "Do you approve this build to promote to production? Selected build [" + env.userSelModule + "]?")
                            env.userProdApproval = 'Approved'
                        }
                    } catch (exception) {
                        env.userProdApproval = '---'
                    }

                    println("User approval to production " + env.userProdApproval);
                }
            }
        }
        stage('Pushing to Prod - maingateway') {
            environment {
                srcTag = 'latest'
                destTag = 'promoteProd'
            }
            when {
                expression {
                    env.userProdApproval == 'Approved'
                }
            }
            steps {
                echo "Deploy to ${PROD_PROJECT} "
                tagImage(params.IMAGE_NAMESPACE, params.PROD_PROJECT, 'maingateway-service', env.srcTag, env.destTag)
                promoteServiceSetup(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'maingateway-service', params.IMAGE_REGISTRY, params.IMAGE_NAMESPACE, env.destTag, params.PROD_PROJECT)
                promoteService(params.IMAGE_NAMESPACE, params.PROD_PROJECT, 'maingateway-service', env.srcTag, env.destTag)
            }
        }
        stage('Pushing to Prod - fisuser') {
            environment {
                srcTag = 'latest'
                destTag = 'promoteProd'
            }
            when {
                expression {
                    env.userProdApproval == 'Approved'
                }
            }
            steps {
                echo "Deploy to ${PROD_PROJECT} "
                tagImage(params.IMAGE_NAMESPACE, params.PROD_PROJECT, 'fuse-user-service', env.srcTag, env.destTag)
                promoteServiceSetup(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'fuse-user-service', params.IMAGE_REGISTRY, params.IMAGE_NAMESPACE, env.destTag, params.PROD_PROJECT)
                setEnvForDBModule(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'fuse-user-service', params.PROD_PROJECT, params.MYSQL_USER, params.MYSQL_PWD)
                promoteService(params.IMAGE_NAMESPACE, params.PROD_PROJECT, 'fuse-user-service', env.srcTag, env.destTag)
            }
        }
        stage('Pushing to Prod - fisalert') {
            environment {
                srcTag = 'latest'
                destTag = 'promoteProd'
            }
            when {
                expression {
                    env.userProdApproval == 'Approved'
                }
            }
            steps {
                echo "Deploy to ${PROD_PROJECT} "
                tagImage(params.IMAGE_NAMESPACE, params.PROD_PROJECT, 'fuse-alert-service', env.srcTag, env.destTag)
                promoteServiceSetup(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'fuse-alert-service', params.IMAGE_REGISTRY, params.IMAGE_NAMESPACE, env.destTag, params.PROD_PROJECT)
                promoteService(params.IMAGE_NAMESPACE, params.PROD_PROJECT, 'fuse-alert-service', env.srcTag, env.destTag)
            }
        }
        stage('Pushing to Prod - nodejsalert') {
            environment {
                srcTag = 'latest'
                destTag = 'promoteProd'
            }
            when {
                expression {
                    env.userProdApproval == 'Approved'
                }
            }
            steps {
                echo "Deploy to ${PROD_PROJECT} "
                tagImage(params.IMAGE_NAMESPACE, params.PROD_PROJECT, 'nodejsalert-ui', env.srcTag, env.destTag)
                promoteServiceSetup(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'nodejsalert-ui', params.IMAGE_REGISTRY, params.IMAGE_NAMESPACE, env.destTag, params.PROD_PROJECT)
                promoteService(params.IMAGE_NAMESPACE, params.PROD_PROJECT, 'nodejsalert-ui', env.srcTag, env.destTag)
            }
        }

        stage('Prod-Env smoke-test') {
            when {
                expression {
                    env.userProdApproval == 'Approved'
                }
            }
            steps {
                script {
                    echo "Waiting for deployment to complete prior starting smoke testing"
                    sleep 80

                    sh "oc project ${PROD_PROJECT}"
                    retry(5) {
                        serviceName = 'fuse-user-service'
                        smokeTestOperation = 'cicd/users/profile/11111'
                        makeGetRequest("http://${serviceName}:8080/${smokeTestOperation}")

                        serviceName = 'fuse-alert-service'
                        smokeTestOperation = 'cicd/alerts'
                        body = ''' { "alertType": "ACCIDENT",  "firstName": "user1",  "date": "11/8/2019",  "phone": "78135955",  "email": "user1@abc.com",  "description": "test"} '''
                        makePostRequest("http://${serviceName}:8080/${smokeTestOperation}", body, 'POST')


                        serviceName = 'maingateway-service'
                        smokeTestOperation = 'cicd/maingateway/profile/11111?alertType=ACCIDENT'
                        makeGetRequest("http://${serviceName}:8080/${smokeTestOperation}")


                        serviceName = 'nodejsalert-ui'
                        makeGetRequest("http://${serviceName}:8080")
                    }
                }
            }
        }

        stage('3scale Publish API to Prod') {
            when {
                expression {
                    env.userProdApproval == 'Approved'
                }
            }
            steps {
                script {


                    def envName = params.PROD_PROJECT
                    def app_name = 'maingateway-service'
                    def backend_service = sh(script: "oc get route ${app_name} -o jsonpath=\'{.spec.host}\' -n ${envName}", returnStdout: true)
                    def targetPort = sh(script: "oc get route ${app_name} -o jsonpath=\'{.spec.port.targetPort}\' -n ${envName}", returnStdout: true)
                    backend_service = "http://" + backend_service
                    println "${backend_service} "

                    echo "Prepare 3scale Configuration"
                    service = toolbox.prepareThreescaleService(
                            openapi: [filename: "cicd-3scale/3scaletoolbox/openapi-spec.json"],
                            environment: [baseSystemName                : params.API_BASE_SYSTEM_NAME,
                                          privateBaseUrl                : backend_service,
                                          privateBasePath               : "/cicd",
                                          environmentName               : envName,
                                          publicStagingWildcardDomain   : params.PUBLIC_STAGING_WILDCARD_DOMAIN != "" ? params.PUBLIC_STAGING_WILDCARD_DOMAIN : null,
                                          publicProductionWildcardDomain: params.PUBLIC_PRODUCTION_WILDCARD_DOMAIN != "" ? params.PUBLIC_PRODUCTION_WILDCARD_DOMAIN : null
                            ],
                            toolbox: [openshiftProject: params.DEV_PROJECT, destination: params.TARGET_INSTANCE,
                                      image           : params.TOOLBOX_IMAGE_REGISTRY,
                                      insecure        : params.DISABLE_TLS_VALIDATION == "yes",
                                      secretName      : params.SECRET_NAME],
                            service: [:],
                            applicationPlans: [
                                    [systemName: "plan1", name: "plan1", defaultPlan: true, costPerMonth: 100, setupFee: 10, trialPeriodDays: 5],
                                    [systemName: "silver", name: "Silver", costPerMonth: 100, setupFee: 10, trialPeriodDays: 5],
                                    [artefactFile: params.PLAN_YAML_FILE_PATH],
                            ],
                            applications: [
                                    [name: envName, description: "This is used for production", plan: "plan1", account: params.DEVELOPER_ACCOUNT_ID]

                            ]
                    )

                    echo "toolbox version = " + service.toolbox.getToolboxVersion()

                    echo "Import OpenAPI"
                    service.importOpenAPI()
                    echo "Service with system_name ${service.environment.targetSystemName} created !"

                    echo "Create an Application Plan"
                    service.applyApplicationPlans()

                    echo "Create an Application"
                    service.applyApplication()

                    echo "Run integration tests"

                    def proxy = service.readProxy("sandbox")
                    def sandbox_endpoint = proxy.sandbox_endpoint

                    retry(5) {

                        sh """set -e -x
                          curl -k -f -w "UserAlert: %{http_code}\n" -o /dev/null -s ${
                            sandbox_endpoint
                        }/cicd/maingateway/profile/11111?alertType=ACCIDENT"&api-key=${service.applications[0].userkey}"
                        """
                    }
                    echo "Promote to production"
                    service.promoteToProduction()

                }
            }
        }

    }
}

def setEnvForDBModule(openShiftHost, openShiftToken, svcName, projName, mysqlUser, mysqlPwd) {
    try {
        sh """ 
        oc rollout pause dc ${svcName} -n ${projName} -n ${projName} 2> /dev/null
        oc set env dc ${svcName} MYSQL_SERVICE_NAME=mysql -n ${projName} 2> /dev/null
        oc set env dc ${svcName} MYSQL_SERVICE_USERNAME=${mysqlUser} -n ${projName} 2> /dev/null
        oc set env dc ${svcName} MYSQL_SERVICE_PASSWORD=${mysqlPwd} -n ${projName} 2> /dev/null
        oc set env dc ${svcName} JAVA_APP_DIR=/deployments -n ${projName} 2> /dev/null
        oc rollout resume dc ${svcName} -n ${projName} -n ${projName} 2> /dev/null
    """
    } catch (Exception e) {
        echo "skip the db environment variable setup, the resources may already exist. " + e.getMessage();
    }
}

def promoteServiceSetup(openShiftHost, openShiftToken, svcName, registry, imageNameSpace, tagName, projName) {
    try {
        sh """
            oc delete dc ${svcName} -n ${projName} 2> /dev/null
        """
    } catch (Exception e) {
        echo "skip dc/svc/route cleanup related exception, the resource may not exist. " + e.getMessage();
    }
    try {
        sh """ 
            oc create dc ${svcName} --image=${registry}/${imageNameSpace}/${svcName}:${tagName} -n ${projName} 2> /dev/null     
            oc rollout pause dc ${svcName} -n ${projName} 2> /dev/null 
            oc patch dc ${
            svcName
        } -p '{"spec": {"template": {"spec": {"containers": [{"name": "default-container","imagePullPolicy": "Always"}]}}}}' -n ${
            projName
        } 2> /dev/null
            oc set env dc ${svcName} APP_NAME=${svcName} -n ${projName} 2> /dev/null 
            oc rollout resume dc ${svcName} -n ${projName} 2> /dev/null 
            oc expose dc ${svcName} --type=ClusterIP  --port=8080 --protocol=TCP --target-port=8080 -n ${projName} 2> /dev/null
            oc expose svc ${svcName} --name=${svcName} -n ${projName} 2> /dev/null 
        """
    } catch (Exception e) {
        echo "skip dc/svc/route creation related exception, the resource may already exist. " + e.getMessage();
    }

}

def tagImage(imageNamespace, projName, svcName, sourceTag, destinationTag) {
    script {
        openshift.withCluster() {
            openshift.withProject(imageNamespace) {
                echo "tagging the build for ${projName} ${sourceTag} to ${destinationTag} in ${imageNamespace} "
                openshift.tag("${svcName}:${sourceTag}", "${svcName}:${destinationTag}")
            }
        }
    }
}

def promoteService(imageNamespace, projName, svcName, sourceTag, destinationTag) {
    script {
        echo "deploying the ${svcName} to ${projName} "
        openshift.withCluster() {
            openshift.withProject(projName) {
                def dply = openshift.selector("dc", svcName)
                echo "waiting for ... " + dply.rollout().status()
            }
        }
    }//script
}

def build(folderName) {
    sh """

    cd ${folderName}

    mvn package -Dmaven.test.skip=true
    """

}

def deploy(folderName, projName, openShiftHost, openShiftToken, mysqlUser, mysqlPwd) {
    sh """
    cd ${folderName}

    oc project ${projName}

    mvn fabric8:deploy -Dmaven.test.skip=true -Dmysql-service-username=${mysqlUser} -Dmysql-service-password=${mysqlPwd}
    """
}

def makePostRequest(url, body, method) {

    sh """set -e -x

    curl -X POST   ${url} \
    -H 'cache-control: no-cache' \
    -H 'content-type: application/json' \
    -d '${body}'

     """

}


def makeGetRequest(url) {


    sh """set -e -x
                          curl -k -f -w "SmokeTest: %{http_code}\n" -o /dev/null -s ${url}
    """
}





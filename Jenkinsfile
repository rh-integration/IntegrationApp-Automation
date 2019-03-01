pipeline {
    agent {
        node {
            label 'maven'
        }
    }
    parameters{ 
        string (defaultValue: 'notinuse', name:'OPENSHIFT_HOST', description:'open shift cluster url')
        string (defaultValue: 'notinuse', name:'OPENSHIFT_TOKEN', description:'open shift token')
        string (defaultValue: 'docker-registry.default.svc:5000', name:'IMAGE_REGISTRY', description:'open shift token')
        string (defaultValue: 'rh-dev', name:'IMAGE_NAMESPACE', description:'name space where image deployed')
        string (defaultValue: 'all', name:'DEPLOY_MODULE', description:'target module to work on')
        string (defaultValue: 'rh-dev', name:'DEV_PROJECT', description:'build or development project')
        string (defaultValue: 'rh-test', name:'TEST_PROJECT', description:'Test project')
        string (defaultValue: 'rh-prod', name:'PROD_PROJECT', description:'Production project')
        string (defaultValue: 'https://github.com/RHsyseng/IntegrationApp-Automation.git', name:'GIT_REPO', description:'Git source')
        string (defaultValue: 'master', name:'GIT_BRANCH', description:'Git branch in the source git')
        string (defaultValue: 'dbuser', name:'MYSQL_USER', description:'My Sql user name')
        string (defaultValue: 'password', name:'MYSQL_PWD', description:'My Sql user password')
        booleanParam (defaultValue: false, name:'SELECT_BUILD_MODULE', description:'Select module to build (default: build all to dev and test)')
        booleanParam (defaultValue: false, name:'SELECT_DEPLOY_TO_PROD', description:'Approval to deploy to Production (default: no deployment to production)')
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
                        timeout (time:180, unit:'SECONDS') {
                            env.userSelModule = input(id: 'userInput', message: 'Please select which module to bulid?',
                            parameters: [[$class: 'ChoiceParameterDefinition', defaultValue: 'strDef', 
                               description:'describing choices', name:'nameChoice', choices: "Gateway\nFisUser\nFisAlert\nUI\nAll"]
                            ])
                        }
                    } catch (exception) {
                      env.userSelModule='All'    
                    }
        
                    println("User selected module " + env.userSelModule);
                }
            }
        }
        stage ('source from git') {
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
        stage('Build fisuser-service') {
            environment { 
                serviceName = 'fisuser-service'
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
        stage('Build fisalert-service') {
            environment { 
                serviceName = 'fisalert-service'
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
                node ('nodejs') {
                    git url: params.GIT_REPO, branch: params.GIT_BRANCH                
 
                    script {
                        sh """
                        cd ${serviceName}

                        oc project ${DEV_PROJECT}

                        npm install && npm run openshift
                        """
                    }
                } 
            }
        }
        stage('Smoke Test') {
            when {
                expression {
                    params.SELECT_DEPLOY_TO_PROD == false 
                }
            }
            steps {
                script {
                    serviceName = 'maingateway-service'
                    smokeTestOperation='cicd/maingateway/profile/11111?alertType=ACCIDENT'
                    makeGetRequest("http://${serviceName}/${smokeTestOperation}")


                    serviceName = 'fisuser-service'
                    smokeTestOperation='cicd/user/profile/11111'
                    makeGetRequest("http://${serviceName}/${smokeTestOperation}")

                    serviceName = 'fisalert-service'
                    smokeTestOperation='cicd/alert'
                    body = ''' { "alertType": "ACCIDENT",  "firstName": "Abdul Hameed",  "date": "11/8/2019",  "phone": "78135955",  "email": "ahameed@redhat.com",  "description": "test"} '''
                    makePostRequest("http://${serviceName}/${smokeTestOperation}", body,'POST')

                    serviceName = 'nodejsalert-ui'
                    makeGetRequest("http://${serviceName}:8080")
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
               promoteServiceSetup(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'maingateway-service',params.IMAGE_REGISTRY, params.IMAGE_NAMESPACE, env.destTag, params.TEST_PROJECT)
               promoteService(params.IMAGE_NAMESPACE, params.TEST_PROJECT,'maingateway-service', env.srcTag, env.destTag)
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
                promoteServiceSetup(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'fisuser-service',params.IMAGE_REGISTRY, params.IMAGE_NAMESPACE, env.destTag, params.TEST_PROJECT)    
                setEnvForDBModule(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'fisuser-service', params.TEST_PROJECT,  params.MYSQL_USER, params.MYSQL_PWD)
                promoteService(params.IMAGE_NAMESPACE, params.TEST_PROJECT, 'fisuser-service', env.srcTag, env.destTag)
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
                promoteServiceSetup(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'fisalert-service',params.IMAGE_REGISTRY, params.IMAGE_NAMESPACE, env.destTag, params.TEST_PROJECT)
                promoteService(params.IMAGE_NAMESPACE, params.TEST_PROJECT, 'fisalert-service', env.srcTag, env.destTag)
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
                promoteServiceSetup(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'nodejsalert-ui',params.IMAGE_REGISTRY, params.IMAGE_NAMESPACE, env.destTag, params.TEST_PROJECT)
                promoteService(params.IMAGE_NAMESPACE, params.TEST_PROJECT, 'nodejsalert-ui', env.srcTag, env.destTag)
            }
        }

	stage('3scale Publish API to Test') {
		steps {
		 script {
			def envName = params.TEST_PROJECT
			def token=params.API_TOKEN
			def adminBaseUrl=params.THREESCALE_URL
			def backendServiceSwaggerEndpoint=params.SWAGGER_FILE_NAME
			def endpoint= params.END_POINT
			def sandbox_endpoint= params.SANDBOX_END_POINT
			def serviceSystemName=params.OPENSHIFT_SERVICE_NAME+"-"+envName.toLowerCase() 
			def app_name= 'maingateway-service' 
			def backend_service = sh(script: "oc get route ${app_name} -o jsonpath=\'{.spec.host}\' -n ${envName}", returnStdout: true)
			def targetPort = sh(script: "oc get route ${app_name} -o jsonpath=\'{.spec.port.targetPort}\' -n ${envName}", returnStdout: true)
			backend_service=  targetPort+"://"+backend_service
			println "${backend_service} "   
			publish3scaleService(adminBaseUrl,token, backendServiceSwaggerEndpoint,serviceSystemName, endpoint, backend_service,sandbox_endpoint,envName)
				
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
                        timeout (time:2, unit:'HOURS') {
                            env.userProdApproval = input(id: 'userInput', message: "Do you approve this build to promote to production? Selected build [" +  env.userSelModule + "]?")
                            env.userProdApproval = 'Approved'
                        } 
                    } catch (exception) {
                      env.userProdApproval='---'    
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
                
                promoteServiceSetup(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'maingateway-service',params.IMAGE_REGISTRY, params.IMAGE_NAMESPACE, env.destTag, params.PROD_PROJECT)
                promoteService(params.IMAGE_NAMESPACE, params.PROD_PROJECT, 'maingateway-service',  env.srcTag, env.destTag)
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
                promoteServiceSetup(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'fisuser-service',params.IMAGE_REGISTRY, params.IMAGE_NAMESPACE, env.destTag, params.PROD_PROJECT)
                setEnvForDBModule(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'fisuser-service', params.PROD_PROJECT,  params.MYSQL_USER, params.MYSQL_PWD)                
                promoteService(params.IMAGE_NAMESPACE, params.PROD_PROJECT, 'fisuser-service', env.srcTag, env.destTag)
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
                promoteServiceSetup(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'fisalert-service',params.IMAGE_REGISTRY, params.IMAGE_NAMESPACE, env.destTag, params.PROD_PROJECT)
                promoteService(params.IMAGE_NAMESPACE, params.PROD_PROJECT, 'fisalert-service', env.srcTag, env.destTag)
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
                promoteServiceSetup(params.OPENSHIFT_HOST, params.OPENSHIFT_TOKEN, 'nodejsalert-ui',params.IMAGE_REGISTRY, params.IMAGE_NAMESPACE, env.destTag, params.PROD_PROJECT)
                promoteService(params.IMAGE_NAMESPACE, params.PROD_PROJECT, 'nodejsalert-ui', env.srcTag, env.destTag)
            }
        }

	stage('3scale Publish API to Prod') {
	 when {
                 expression {
                    params.SELECT_DEPLOY_TO_PROD == true
                }
            }   
	steps {
		script {
			def envName = params.PROD_PROJECT
			def token=params.API_TOKEN
			def adminBaseUrl=params.THREESCALE_URL
			def backendServiceSwaggerEndpoint=params.SWAGGER_FILE_NAME
			def endpoint= params.END_POINT
			def sandbox_endpoint= params.SANDBOX_END_POINT
			def serviceSystemName=params.OPENSHIFT_SERVICE_NAME+"-"+envName.toLowerCase() 
			def app_name= 'maingateway-service' 
			def backend_service = sh(script: "oc get route ${app_name} -o jsonpath=\'{.spec.host}\' -n ${envName}", returnStdout: true)
			def targetPort = sh(script: "oc get route ${app_name} -o jsonpath=\'{.spec.port.targetPort}\' -n ${envName}", returnStdout: true)
			backend_service=  targetPort+"://"+backend_service
			println "${backend_service} "   
			publish3scaleService(adminBaseUrl,token, backendServiceSwaggerEndpoint,serviceSystemName, endpoint, backend_service,sandbox_endpoint,envName)
				
		}
	   }
	}
     
    }
}
def setEnvForDBModule(openShiftHost, openShiftToken, svcName, projName, mysqlUser, mysqlPwd) {
    try {
    sh """ 
        oc set env dc ${svcName} MYSQL_SERVICE_NAME=mysql -n ${projName} 2> /dev/null
        oc set env dc ${svcName} MYSQL_SERVICE_USERNAME=${mysqlUser} -n ${projName} 2> /dev/null
        oc set env dc ${svcName} MYSQL_SERVICE_PASSWORD=${mysqlPwd} -n ${projName} 2> /dev/null
        oc set env dc ${svcName} JAVA_APP_DIR=/deployments -n ${projName} 2> /dev/null
        oc rollout cancel dc ${svcName} -n ${projName} -n ${projName} 2> /dev/null

    """
    } catch (Exception e) {
      echo "skip the db environment variable setup, the resources may already exist. " + e.getMessage();
    }
}
def promoteServiceSetup(openShiftHost, openShiftToken, svcName,registry,imageNameSpace, tagName, projName) {
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
            oc set env dc ${svcName} APP_NAME=${svcName} -n ${projName} 2> /dev/null 
            oc rollout cancel dc ${svcName} -n ${projName} 2> /dev/null 
            oc expose dc ${svcName} --type=ClusterIP  --port=80 --protocol=TCP --target-port=8080 -n ${projName} 2> /dev/null
            oc expose svc ${svcName} --name=${svcName} -n ${projName} 2> /dev/null 
        """
    } catch (Exception e) {
      echo "skip dc/svc/route creation related exception, the resource may already exist. " + e.getMessage();
    }

}
def promoteService (imageNamespace, projName, svcName, sourceTag, destinationTag) {
    script {
         openshift.withCluster() {
             openshift.withProject( imageNamespace ) {
                 echo "tagging the build for ${projName} ${sourceTag} to ${destinationTag} in ${imageNamespace} "
                 openshift.tag("${svcName}:${sourceTag}", "${svcName}:${destinationTag}")
             }
         }
         echo "deploying the ${svcName} to ${projName} "
         openshift.withCluster() {
             openshift.withProject( projName) {
                def dply = openshift.selector("dc", svcName)
                echo "waiting for ... "+ dply.rollout().status()
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

	println('service url...'+url);
	println('post body...'+body)

	def post = new URL(url).openConnection();
	post.setRequestMethod(method)
	post.setDoOutput(true)
	post.setRequestProperty('Content-Type', 'application/json')
	post.setRequestProperty('Accept', 'application/json')
	post.getOutputStream().write(body.getBytes('UTF-8'))
	def responseCode = post.getResponseCode();
	if (responseCode != 200 && responseCode != 201) {
		println('Failed. HTTP response: ' + responseCode)
		println(post.getInputStream().getText());
		assert false
	} else {
		println('Tested successfully!')
		println(post.getInputStream().getText());

	}
}

//////// 3scale API Publishing ////////////////////////////
import groovy.json.JsonOutput
import groovy.json.JsonSlurperClassic 
import javax.net.ssl.HostnameVerifier
import javax.net.ssl.HttpsURLConnection
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManager
import javax.net.ssl.X509TrustManager
import java.security.SecureRandom
import java.net.URLEncoder

def publish3scaleService(
		String adminBaseUrl,
		String token,
		String backendServiceSwaggerEndpoint,
		String serviceSystemName,
		String endpoint,
		String api_backend,
		String sandbox_endpoint,
		String envName) {

	def jsonSlurper = new JsonSlurperClassic()
	def servicesEndpoint = "${adminBaseUrl}/admin/api/services.json?access_token=${token}"
	def services =  jsonSlurper.parseText(new URL(servicesEndpoint).getText()).services
	if(services.find { it.service['system_name'] == serviceSystemName }){
        	def serviceJson= services.find { it.service['system_name'] == serviceSystemName}                
        	def serviceid=serviceJson.service.id                  
        	UpdateService(adminBaseUrl,token,backendServiceSwaggerEndpoint,serviceSystemName,endpoint,api_backend,sandbox_endpoint,envName,serviceid,jsonSlurper)
        }else{
		createNewService(adminBaseUrl,token,backendServiceSwaggerEndpoint,serviceSystemName,endpoint,api_backend,sandbox_endpoint,envName,jsonSlurper)
        }

	
}
def createNewService(
        String adminBaseUrl,
		String token,
		String backendServiceSwaggerEndpoint,
		String serviceSystemName,
		String endpoint,
		String api_backend,
		String sandbox_endpoint,
		String envName,
		JsonSlurperClassic jsonSlurper){
    
	println('Fetching service swagger json...')
	def swaggerDoc = jsonSlurper.parseText(new URL(backendServiceSwaggerEndpoint).getText())
	println('Creating Service...')
	def activeDocSpecCreateUrl = "${adminBaseUrl}/admin/api/services.json"
	def name = swaggerDoc.info.title != null ? swaggerDoc.info.title : serviceSystemName
	def api_version=swaggerDoc.info.version
	name=name + "(" +envName+", v"+api_version+")" 
	
	def data = "access_token=${token}&name=${name}&system_name=${serviceSystemName}"
	def responseBody=makeRequestwithBody(activeDocSpecCreateUrl, data, 'POST')
	def serviceresponse = jsonSlurper.parseText(responsbody)
	def serviceid = serviceresponse.service.id
	println("Service Id = "+serviceid);
	
	println('Creating application_plans...')
	def serviceurl =adminBaseUrl+"/admin/api/services/";
	def apiurl = serviceurl+serviceid+"/application_plans.json";
	data = "access_token=${token}&name=test&system_name=${serviceSystemName}"
	responseBody=makeRequestwithBody(apiurl, data, 'POST')
	serviceresponse = jsonSlurper.parseText(responsbody)
	def application_plan_id = serviceresponse.application_plan.id

        serviceurl =adminBaseUrl+"/admin/api/services/"+serviceid+"/metrics.json";
        responseBody=makeGetRequest(serviceurl+"?access_token=${token}")
        Map mapserviceresponse = jsonSlurper.parseText(responsbody)
        def metricId
        if(mapserviceresponse.metrics){

		metricId= mapserviceresponse.metrics[0].metric.id

        }  
	println("metricId = "+metricId);

	println("creating API limit");
	def period="minute"
	def periodValue=100
	serviceurl =adminBaseUrl+"/admin/api/application_plans/";	
	apiurl = serviceurl+application_plan_id+"/metrics/"+metricId+"/limits.json";
	data = "access_token=${token}&period=${period}&value=${periodValue}"
	responseBody=makeRequestwithBody(apiurl, data, 'POST')
	serviceresponse = jsonSlurper.parseText(responsbody)
      
	println('fetching account details')
  	serviceurl =adminBaseUrl+"/admin/api/accounts.json";
	apiurl = serviceurl
	responseBody=makeGetRequest(apiurl+"?access_token=${token}")
	mapserviceresponse = jsonSlurper.parseText(responsbody)
	def accountId
	def org_name;
	if(mapserviceresponse.accounts){

	 	accountId= mapserviceresponse.accounts[0].account.id
	 	org_name= mapserviceresponse.accounts[0].account.org_name
	}  
	println("account id = "+accountId);
   
	println('Creating application...')
	serviceurl = adminBaseUrl+"/admin/api/accounts/";
	apiurl = serviceurl+accountId+"/applications.json";
	data = "access_token=${token}&plan_id=${application_plan_id}&name=${serviceSystemName+"App"}&description=testfuse"
	responseBody=makeRequestwithBody(apiurl, data, 'POST')
	serviceresponse = jsonSlurper.parseText(responsbody)
    
	println('Creating Proxy Setting...')
	serviceurl = adminBaseUrl+"/admin/api/services/";
	apiurl = serviceurl+serviceid+"/proxy.json";
	data = "access_token=${token}&endpoint=${URLEncoder.encode(endpoint, 'UTF-8')}&api_backend=${URLEncoder.encode(api_backend, 'UTF-8')}&sandbox_endpoint=${URLEncoder.encode(sandbox_endpoint, 'UTF-8')}"
	responseBody=makeRequestwithBody(apiurl, data, 'PATCH')
	serviceresponse = jsonSlurper.parseText(responsbody)
     
	serviceurl = adminBaseUrl+"/admin/api/services/";
	apiurl = serviceurl+serviceid+"/proxy/configs/sandbox/latest.json";
	responseBody=makeGetRequest(apiurl+"?access_token=${token}")
	serviceresponse = jsonSlurper.parseText(responsbody)
	def version = serviceresponse.proxy_config.version
	println('current version is....'+version)	
   
	println('Promte to Production...')
	serviceurl = adminBaseUrl+"/admin/api/services/";
	apiurl = serviceurl+serviceid+"/proxy/configs/sandbox/"+version+"/promote.json";
	data = "access_token=${token}&to=production"
	responseBody=makeRequestwithBody(apiurl, data, 'POST')
	serviceresponse = jsonSlurper.parseText(responsbody)

	println('Creates a method under a metric....')  
	def paths = swaggerDoc.paths.keySet() as List
	paths.each { path ->
		def methods = swaggerDoc.paths[path].keySet() as List
		methods.each {
			
		friendly_name=swaggerDoc.paths[path][it].operationId
                serviceurl = adminBaseUrl+"/admin/api/services/";
   				apiurl = serviceurl+serviceid+"/metrics/"+metricId+"/methods.json";
        	data = "access_token=${token}&friendly_name=${friendly_name}&unit=String"
                responseBody=makeRequestwithBody(apiurl, data, 'POST')
                serviceresponse = jsonSlurper.parseText(responsbody)
     		
		            }
                  }

	println('Creates a Proxy Mapping Rule.....')  
	http_method ="GET"     
	def basepath=swaggerDoc.basePath
	paths = swaggerDoc.paths.keySet() as List
	paths.each { pattern ->
	       
		serviceurl = adminBaseUrl+"/admin/api/services/";
		apiurl = serviceurl+serviceid+"/proxy/mapping_rules.json";
		data = "access_token=${token}&http_method=${http_method}&pattern=${basepath}${pattern}&delta=1&metric_id=${metricId}'"
		responseBody=makeRequestwithBody(apiurl, data, 'POST')
		serviceresponse = jsonSlurper.parseText(responsbody)
		}

	update3scaleActiveDoc(adminBaseUrl,token,endpoint,backendServiceSwaggerEndpoint,serviceSystemName,jsonSlurper) 
      
}
  
def UpdateService(String adminBaseUrl,
		String token,
		String backendServiceSwaggerEndpoint,
		String serviceSystemName,
		String endpoint,
		String api_backend,
		String sandbox_endpoint,
        	String envName,
        	int serviceid,
		JsonSlurperClassic jsonSlurper  ){
   
	
	def swaggerDoc = jsonSlurper.parseText(new URL(backendServiceSwaggerEndpoint).getText())
	println('updating Service...')
	def name = swaggerDoc.info.title != null ? swaggerDoc.info.title : serviceSystemName
	def api_version=swaggerDoc.info.version
	name=name + "(" +envName+", v"+api_version+")" 
	def apiurl = "${adminBaseUrl}/admin/api/services/"+serviceid+".json"
	def data = "access_token=${token}&name=${name}"
	def responseBody=makeRequestwithBody(apiurl, data, 'PUT')
	
	println('updating Proxy Setting...')
	serviceurl = adminBaseUrl+"/admin/api/services/";
	apiurl = serviceurl+serviceid+"/proxy.json";
	data = "access_token=${token}&endpoint=${URLEncoder.encode(endpoint, 'UTF-8')}&api_backend=${URLEncoder.encode(api_backend, 'UTF-8')}&sandbox_endpoint=${URLEncoder.encode(sandbox_endpoint, 'UTF-8')}"
	responseBody=makeRequestwithBody(apiurl, data, 'PATCH')

 	serviceurl = adminBaseUrl+"/admin/api/services/";
	apiurl = serviceurl+serviceid+"/proxy/configs/sandbox/latest.json";
	responseBody=makeGetRequest(apiurl+"?access_token=${token}")
	Map mapserviceresponse = jsonSlurper.parseText(responsbody)
	def version = mapserviceresponse.proxy_config.version
	println(' version is....'+version)	

	serviceurl = adminBaseUrl+"/admin/api/services/";
	apiurl = serviceurl+serviceid+"/proxy/configs/production/latest.json";
	responseBody=makeGetRequest(apiurl+"?access_token=${token}")
	mapserviceresponse = jsonSlurper.parseText(responsbody)
	//println(serviceresponse);
	def production_version = mapserviceresponse.proxy_config.version
	println(' production_version is....'+production_version)	
	if (production_version!=version){
    		println('Promte to Production...')
		serviceurl = adminBaseUrl+"/admin/api/services/";
		apiurl = serviceurl+serviceid+"/proxy/configs/sandbox/"+version+"/promote.json";
		data = "access_token=${token}&to=production"
		responseBody=makeRequestwithBody(apiurl, data, 'POST')
		serviceresponse = jsonSlurper.parseText(responsbody) 
	}

	serviceurl =adminBaseUrl+"/admin/api/services/"+serviceid+"/metrics.json";
	responseBody=makeGetRequest(serviceurl+"?access_token=${token}")
	mapserviceresponse = jsonSlurper.parseText(responsbody)
	def metricId
	if(mapserviceresponse.metrics){
		metricId= mapserviceresponse.metrics[0].metric.id
	}  

	println("metricId = "+metricId);
	serviceurl = adminBaseUrl+"/admin/api/services/";
	apiurl = serviceurl+serviceid+"/metrics/"+metricId+"/methods.json";
	responseBody=makeGetRequest(apiurl+"?access_token=${token}")
	ArrayList serviceresponseList = jsonSlurper.parseText(responsbody).methods

	println('updates methods under a metric....')  
	def paths = swaggerDoc.paths.keySet() as List
	paths.each { path ->
		def methods = swaggerDoc.paths[path].keySet() as List
			methods.each {
			friendly_name=swaggerDoc.paths[path][it].operationId
				if(!serviceresponseList.find { it.method['system_name'] == friendly_name }){
					println("adding new method "+friendly_name)
					serviceurl = adminBaseUrl+"/admin/api/services/";
					apiurl = serviceurl+serviceid+"/metrics/"+metricId+"/methods.json";
					data = "access_token=${token}&friendly_name=${friendly_name}&unit=String"
					responseBody=makeRequestwithBody(apiurl, data, 'POST')
					serviceresponse = jsonSlurper.parseText(responsbody)
				}
			}
		}

	 update3scaleActiveDoc(adminBaseUrl,token,endpoint,backendServiceSwaggerEndpoint,serviceSystemName,jsonSlurper) 


}

def update3scaleActiveDoc(
		String adminBaseUrl,
		String token,
		String productionRoute,
		String backendServiceSwaggerEndpoint,
		String serviceSystemName,
		JsonSlurperClassic jsonSlurper) {

	def activeDocSpecListUrl = "${adminBaseUrl}/admin/api/active_docs.json?access_token=${token}"
	def servicesEndpoint = "${adminBaseUrl}/admin/api/services.json?access_token=${token}"
	// instantiate JSON parser
	//def jsonSlurper = new JsonSlurper()
	println('Fetching service swagger json...')
	// fetch new swagger doc from service
	def swaggerDoc = jsonSlurper.parseText(new URL(backendServiceSwaggerEndpoint).getText())
	def services =  jsonSlurper.parseText(new URL(servicesEndpoint).getText()).services
	def service = (services.find { it.service['system_name'] == serviceSystemName }).service
	// get the auth config for this service, so we can add the correct auth params to the swagger doc
	def proxyEndpoint = "${adminBaseUrl}/admin/api/services/${service.id}/proxy.json?access_token=${token}"
	def proxyConfig =  jsonSlurper.parseText(new URL(proxyEndpoint).getText()).proxy
	swaggerDoc.host =  new URL(productionRoute).getHost();
	// is the credential in a header or query param?
	def credentialsLocation = proxyConfig['credentials_location'] == 'headers' ? 'header' : 'query'
	// for each method on each path, add the param for credentials
	def paths = swaggerDoc.paths.keySet() as List
	paths.each { path ->
		def methods = swaggerDoc.paths[path].keySet() as List
		methods.each {
			if (!(swaggerDoc.paths[path][it].parameters)) {
				swaggerDoc.paths[path][it].parameters = []
			}
			swaggerDoc.paths[path][it].parameters.push([
				in: credentialsLocation,
				name: proxyConfig['auth_user_key'],
				description: 'User authorization key',
				required: true,
				type: 'string'
			])
		}
	}
	// get all existing docs on 3scale
	println('Fetching uploaded Active Docs...')
	def activeDocs =  jsonSlurper.parseText(new URL(activeDocSpecListUrl).getText())['api_docs']
	// find the one matching the correct service (or not)
	def activeDoc = activeDocs.find { it['api_doc']['system_name'] == serviceSystemName }
	if ( activeDoc ) {
		println('Found Active Doc for ' + serviceSystemName)
		def activeDocId = activeDoc['api_doc'].id
		// update our swagger doc, now containing the correct host and auth params to 3scale
		def activeDocSpecUpdateUrl = "${adminBaseUrl}/admin/api/active_docs/${activeDocId}.json"
		def name = swaggerDoc.info.title != null ? swaggerDoc.info.title : serviceSystemName
		def data = "access_token=${token}&body=${URLEncoder.encode(JsonOutput.toJson(swaggerDoc), 'UTF-8')}&skip_swagger_validations=false"
		makeRequestwithBody(activeDocSpecUpdateUrl, data, 'PUT')
	} else {
		println('Active Docs for ' + serviceSystemName + ' not found in 3scale. Creating a new Active Doc.')
		// post our new swagger doc, now containing the correct host and auth params to 3scale
		def activeDocSpecCreateUrl = "${adminBaseUrl}/admin/api/active_docs.json"
		def name = swaggerDoc.info.title != null ? swaggerDoc.info.title : serviceSystemName
		def data = "access_token=${token}&name=${name}&system_name=${serviceSystemName}&body=${URLEncoder.encode(JsonOutput.toJson(swaggerDoc), 'UTF-8')}&skip_swagger_validations=false"
		makeRequestwithBody(activeDocSpecCreateUrl, data, 'POST')
	}
}



def makeGetRequest(url) {
        println(url)
	def get = new URL(url).openConnection();
	get.setDoOutput(true)
	get.setRequestProperty('Accept', 'application/json')
	def responseCode = get.getResponseCode();
	if (responseCode != 200 && responseCode != 201) {
		println('Failed. HTTP response: ' + responseCode)
		println(get.getInputStream().getText());
		assert false
	} else {
		println('called successfully!')
		responsbody=get.getInputStream().getText()
         	return responsbody
	 }
}

def  makeRequestwithBody(url, body, method) {
  
	println(url)  
	println(body)  
	def post = new URL(url).openConnection();
	post.setRequestMethod("POST")
	post.setDoOutput(true)
	post.setRequestProperty('Content-Type', 'application/x-www-form-urlencoded')
	if(method!="POST"){  
		post.setRequestProperty("X-HTTP-Method-Override", method);
	 }
	post.getOutputStream().write(body.getBytes("UTF-8"));
	def postRC = post.getResponseCode();
	println( post.getResponseCode());
	if (postRC != 200 && postRC != 201) {
	   println('Failed to update/create . HTTP response: ' + postRC)
		responsbody=post.getInputStream().getText()
		assert false
	} else {
		println('created successfully!')
		responsbody=post.getInputStream().getText()
		return responsbody

	}
}


///////////end of 3scale ////////////////////////////////////


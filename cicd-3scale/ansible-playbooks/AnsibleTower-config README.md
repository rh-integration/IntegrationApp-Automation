# 3scale Ansible Tower setup


### 2/ Create the ansible tower project:

oc new-project ansible --display-name="Ansible Tower"



### 3/ Prepare your 3scale SaaS Tenant

Create an Access Token in your 3scale SaaS Tenant that has read-write access to the Account Management API. Please check [3scale documentation](https://access.redhat.com/documentation/en-us/red_hat_3scale/2-saas/html-single/accounts/index#access_tokens) on how to get an access token. Write down this value for later use.

You will also need the name of your 3scale tenant.

On your 3scale Admin Portal, go the `Developer Portal` section and replace your standard `Documentation` page by [the content of 3scale-docs.html](3scale-docs.html).


**Do not forget to hit `Save` and `Publish`.**



### 4/ Deploy Ansible Tower

```sh
oc project ansible
oc apply -f - <<EOF
apiVersion: "v1"
kind: "PersistentVolumeClaim"
metadata:
  name: "postgresql"
spec:
  accessModes:
    - "ReadWriteOnce"
  resources:
    requests:
      storage: "5Gi"
EOF
```

> Note: since AWX moves very fast, it is recommended to settle the version of all components.

```sh
git clone https://github.com/ansible/awx.git
git clone https://github.com/ansible/awx-logos.git
cd awx
git checkout 2b9954c .
cd installer
ansible-playbook -i inventory install.yml -e kubernetes_web_version=1.0.7.2 -e kubernetes_web_version=1.0.7.2 -e openshift_host="$(oc whoami --show-server)" -e openshift_skip_tls_verify=true -e openshift_project="$(oc project -q)" -e openshift_user="$(oc whoami)" -e openshift_token="$(oc whoami -t)" -e admin_user=admin -e admin_password=redhat123 -e awx_official=true
```

The default installation of AWX uses a combination of `latest` tags and an `imagePullPolicy` set to `always`, which is a recipe for disaster. All tags have been set explicitely on the command line earlier, now you can set the `imagePullPolicy` to `IfNotPresent`.

```sh
oc patch dc/awx --type=json -p '[ { "op": "replace", "path": "/spec/template/spec/containers/0/imagePullPolicy", "value": "IfNotPresent" }, { "op": "replace", "path": "/spec/template/spec/containers/1/imagePullPolicy", "value": "IfNotPresent" }, { "op": "replace", "path": "/spec/template/spec/containers/2/imagePullPolicy", "value": "IfNotPresent" }, { "op": "replace", "path": "/spec/template/spec/containers/3/imagePullPolicy", "value": "IfNotPresent" } ]'
```

### 5/ Configure project and job in AWX

Login on AWX as admin, go to the *Projects* section and add a new project with following properties :

* Name: `Deploy API to 3scale`
* Description: `Enable continuous deployment of an API to 3scale AMP`
* Organization: `default`
* SCM Type: `Git`
* SCM URL: `https://github.com/nmasse-itix/threescale-cicd-awx`
* SCM Branch/Tag/Commit: `master`

You can also tick `Update Revision on Launch` and setup a cache timeout.

Then you have to add a new *Job Template* with following properties :

* Name: `Deploy an API to 3scale`
* Project: `Deploy API to 3scale`
* Playbook: `deploy-api.yml`
* Inventory: `Prompt on Launch`
* Extra-variables: `Prompt on Launch`

For both the TEST and PROD environments, you will have to declare an inventory into AWX.

* Create an inventory named `3scale-test` and set the `Variables` field to:

```yaml
---
ansible_connection: local
```

* Save
* Move to the `Groups` section and create a group named `threescale`
* Set the `Variables` field to:

```yaml
---
threescale_cicd_access_token: <3scale_access_token>
threescale_cicd_api_environment_name: test
threescale_cicd_wildcard_domain: test.app.itix.fr
```

* Do not forget to replace the `threescale_cicd_access_token`, `threescale_cicd_api_environment_name` and `threescale_cicd_wildcard_domain` variables with respectively your access token to 3scale API Management backend, the name of environment as well as the wildcard that will be used to serve Gateway through Route.

* Move to the `Hosts` section
* Add a host that matches your 3scale Admin Portal (`<TENANT>-admin.3scale.net`). For example: `nmasse-redhat-admin.3scale.net`

* Duplicate this inventory and change the `threescale` group variables to:

```yaml
---
threescale_cicd_access_token: <3scale_access_token>
threescale_cicd_api_environment_name: prod
threescale_cicd_wildcard_domain: prod.app.itix.fr
```

* Change the name of the new inventory to `3scale-prod` and save



## 6/ Jenkins setup for Ansible Tower

You finally need to configure the connection between Jenkins and AWX/Ansible Tower. To do this, go to Jenkins, click on *Manage Jenkins* > *Manage Plugins* and install the `Ansible Tower` plugin. You do not need to restart Jenkins.

Then click on *Credentials* > *System*, click on *Global credentials (unrestricted)* and select *Add Credentials...* to add a new user for connection to AWX/Ansible Tower. Fill-in your AWX/Tower Admin login and password, and choose `tower-admin` for the id field.

Finally, you also have to configure an alias to your AWX Server into Jenkins. This will allow our Jenkins pipelines to access the AWX server easily without knowing the complete server name or address. Click on *Configure System* in the management section and then go to the *Ansible Tower* section and add a new Tower Installation. Give it a name (we've simply used `tower` in our scripts), fill the URL and specify that it should be accessed using the user and credentials we have just created before.


### 7/ Create the Jenkins Pipeline

* review the pipelinetemplates/three-scale-pipeline-template.yaml` paramets and change it as per your configuration and save it.


     * below are list of paramertes:
        * GIT_REPO=<Your git Repo example:https://github.com/redhatHameed/3ScaleFuseAMQ.git>
        * GIT_BRANCH=master
        * API_URL=<API URL example : maingateway-service-cicddemo.app.rhdp.ocp.cloud.lab.eng.bos.redhat.com:80>
        * Threescale cicd wildcard domain=<WILD CARD DOMAIN example : app.rhdp.**.**.com>
        * Threescale API CAST Major Version=1
        * SWAGGER_FILE_NAME=openapi-spec.yaml
        * ANSIBLE_TEST_INVENTORY=3scale-test
        * ANSIBLE_PROD_INVENTORY=3scale-prod
        * ANSIBLE_JOB_TEMPLATE=Deploy an API to 3scale
        * ANSIBLE_TOWER_SERVER=tower
        * ANSIBLE_SMOKE_TEST_OPREATION=<route2: name of smoke test method>
        * ROUTE_SERVICE_NAME=3scale-prod
        * API_CAST_ROUTE_TEMPLATE_FILE=https://github.com/redhatHameed/IntegrationApp-Automation/blob/master/apicast-routes-template.yaml
        * The Name of API CAST Gateway Project or 3scale project name deployed on Openshift to create the routes=<ah-3scale-ansible>


- Go to your OpenShift Jenkins Project 

- oc create -f pipelinetemplates/three-scale-pipeline-template.yaml

- oc new-app pipeline-threescale-publish

* review the three-scale-pipeline-template.yaml` and change it as per your configuration and save it.

## 8/ Running the Demo

- Go to your OpenShift jenkins project where pipline created
- Go to `Build` > `Pipelines`
- Click on the `pipeline`
- Click `Start Pipeline`
- Go to ansible tower check the jobs status
- Login to 3scale , and check the API section.


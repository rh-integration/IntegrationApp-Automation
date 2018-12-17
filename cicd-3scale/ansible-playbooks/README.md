# 3scale Ansible CICD



## Requirements

This role requires:

- an instance of 3scale API Management Platform (hosted or on-premise)
- APIcast gateways (staging and production), either hosted or self-managed
- a Swagger 2.0 file describing the API you want to publish


On the control node, the `jmespath` library is required. install it with:

```sh
pip install jmespath
```

Jinja (2.8) is also required. You can upgrade your Jinja version with:

```sh
pip install -U Jinja2
```

If your control node runs on RHEL7, you can run
[this playbook](https://github.com/nmasse-itix/OpenShift-Lab/blob/master/common/verify-local-requirements.yml)
to install the missing dependencies.

## Steps: Publish an API on 3scale 
 
 1. Craft a Swagger file for API
 2. Build your inventory file
 3. Write the playbook
 4. Run the playbook!

1.Generate Swagger file of your api and to secure your API with API Key add below lines in Swagger file
```yaml
security:
- apikey: []
securityDefinitions:
  apikey:
    name: api-key
    in: header
    type: apiKey
```

Write the `inventory` file:


```ini
[all:vars]
ansible_connection=local

[threescale]
<TENANT>-admin.3scale.net

[threescale:vars]
threescale_cicd_access_token=<ACCESS_TOKEN>
threescale_cicd_api_environment_name=test
threescale_cicd_wildcard_domain=<DOMNA NAME>

```


write the playbook (`deploy-api.yaml`):

```yaml
- hosts: threescale
  gather_facts: no
  vars:
    threescale_cicd_openapi_file: openapi-spec.yaml
    threescale_cicd_api_backend_hostname: '<API URL>'
    threescale_cicd_api_backend_scheme: http
    threescale_cicd_api_base_system_name: 3scale-prod
    threescale_cicd_openapi_smoketest_operation: route2
    threescale_cicd_validate_openapi: false
  roles:
  - nmasse-itix.threescale-cicd
```

## create requirment file under role folder. 

roles/requirements.yml

---
- src: nmasse-itix.threescale-cicd
  version: master


## Running the playbooks


```sh

./runansible.sh

or 

ansible-galaxy install nmasse-itix.threescale-cicd
ansible-playbook -i inventory deploy-api.yaml
```
update the role to its latest version with:

```sh
   ansible-galaxy install -f nmasse-itix.threescale-cicd,master -p roles/
```

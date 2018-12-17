#ansible-playbook -i inventory deploy-api.yaml
ansible-galaxy install -f nmasse-itix.threescale-cicd,master -p roles/
ansible-playbook -i inventory deploy-api.yaml


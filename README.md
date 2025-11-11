# devops-task
DevOps Engineer Task

### Setup Instructions

1. SSH key in github

2. Install `git` and `ansible`
```
apt update && apt upgrade -y
apt install -y git ansible
```

3. Clone this repo:
```
git clone git@github.com:Amirbekyan/devops-task.git
cd devops-task
```

4. Install prerequisites:
```
ansible-playbook -i localhost src/ansible-requirements.yml
```

5. Run Terraform code:
>[!IMPORTANT]
> Copy `terraform.tfvars.sample` to `terraform-tfvars` and update values with real ones before applying the code.

>[!TIP]
> [Webhook.site](https://webhook.site/) can be used to generate temporary webhook URLs for testing.

```
tofu init
tofu apply
```

6. 
```
ansible-playbook -i localhost src/ansible-docker-build.yml
```

7. add to `/etc/hosts`
```
<host-ip>	preview.hello.devops-task hello.devops-task argocd.devops-task grafana.devops-task alert.devops-task prometheus.devops-task
```


### Regrets
Initially I planned to setup Argo Events and Argo Workflows to build the sample app images continuously on the Minikube itself.  Unfortunately I was short in time due to my travel to USA to attend KubeCon & CloudNativeCon NA 2025.  I had no other choice than to imitate the CI with an ansible playbook.  Peachy greetings from Atlanta :). 
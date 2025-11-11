# devops-task
DevOps Engineer Task

### Setup Instructions
The below instructions are compatibe with and tested on Debian 13.

Use the automated setup script or proceed with manual setup described below:

```
curl -sL https://raw.githubcontent | bash
```

#### Manual setup

1. Install `git` and `ansible`
```
apt update && apt upgrade -y
apt install -y git ansible
```

2. Clone this repo:
```
git clone https://github.com/Amirbekyan/devops-task.git
cd devops-task
```

3. Install prerequisites:
```
ansible-playbook -i localhost src/ansible-minikube.yml
```

4. Run Terraform code:
>[!IMPORTANT]
> Copy `terraform.tfvars.sample` to `terraform-tfvars` and update values with real ones before applying the code.

>[!TIP]
> [Webhook.site](https://webhook.site/) can be used to generate temporary webhook URLs for testing.
> GitHub credentials are optional for this repo as it's public.

```
tofu init
tofu apply
```

5. Pre-build `devops-task` local image tags `alpha` and `bravo` for CD demo:
```
ansible-playbook -i localhost src/ansible-docker-build.yml
```

7. Add records for ingress hostnames in `/etc/hosts` to point to Minikube host address:
```
<host-ip>	preview.hello.devops-task hello.devops-task argocd.devops-task grafana.devops-task alert.devops-task prometheus.devops-task
```

Congratulations!  You've successfully set up the `devops-task` environment.

### Usage

Here are the endpoints we've setup so far:

* [Grafana](http://grafana.devops-task:32080/)
  Grafana visualizes metrics, logs and traces, checkout:
    * Dashboards for metrics
    * Explore or Dilldown for logs and traces

* [Prometheus](http://prometheus.devops-task:32080/)
  Prometheus is used to collect and store metrics, as well as triggering alerts, checkout 'Alerts' page for configured alerts.
  ![rules](/docs/img/prometheus.png)
  The screenshot above shows that an alert will be triggered each time percentage of 4xx requests exceeds 5% of all requests.

* [Alert Manager](http://alert.devops-task:32080/)
  Alert Manager handles alerts routing and notifications.
  ![alerts](/docs/img/alertmanager.png)

* [ArgoCD](http://argocd.devops-task:32080/)
  We'll use ArgoCD to deploy our Sample App to Minikube in the next step.

* [Sample App](http://hello.devops-task:32080/)
  [Sample App new version preview](http://preview.hello.devops-task:32080/)
  Sample App current (and preview - in case of Rollout) home pages




### Regrets
Initially I planned to setup Argo Events and Argo Workflows to build the sample app images continuously on the Minikube itself.  Unfortunately I was short in time due to my travel to USA to attend KubeCon & CloudNativeCon NA 2025.  I had no other choice than to imitate the CI with an ansible playbook.  Peachy greetings from Atlanta :). 
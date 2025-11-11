# devops-task
DevOps Engineer Task

### Setup Instructions
The below instructions are compatibe with and tested on Debian 13.

Use the automated setup script or proceed with manual setup described below:

```
curl -sL https://raw.githubusercontent.com/Amirbekyan/devops-task/refs/heads/main/src/setup.sh | bash
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

  ![grafana](/docs/img/grafana.png)

* [Prometheus](http://prometheus.devops-task:32080/)
  Prometheus is used to collect and store metrics, as well as triggering alerts, checkout 'Alerts' page for configured alerts.

  ![rules](/docs/img/prometheus.png)

  The screenshot above shows that an alert will be triggered each time percentage of 4xx requests exceeds 5% of all requests.

* [Alert Manager](http://alert.devops-task:32080/)
  Alert Manager handles alerts routing and notifications.

  ![alerts](/docs/img/alertmanager.png)

* [ArgoCD](http://argocd.devops-task:32080/)
  We'll use ArgoCD to deploy our Sample App to Minikube in the next step.
  ArgoCD will send alerts to the same channels as Alert Manager in case of application creation, updates, degradation, deletion and sync issues.

* [Sample App](http://hello.devops-task:32080/)
  [Sample App new version preview](http://preview.hello.devops-task:32080/)
  Sample App current (and preview - in case of Rollout) home pages


Head to ArgoCD page and create an app with this params:

* applicaton name: `<name-of-your-choice>`
* project name: `default`
* sync policy: `Automatic`
* sync options: `Auto-Create Namespace`
* repository url: `https://github.com/amirbekyan/devops-task.git`
* revision: `HEAD`
* path: `app/chart/olleh`
* cluster url: `https://kubernetes.default.svc`
* namespace: `<namespace-of-your-choice>`
* parameters:
    * image.tag: `alpha`
    * ingress.enabled: `true`
    * rollout.enabled: `true`
    * replicaCount: `3`

```
project: default
source:
  repoURL: https://github.com/amirbekyan/devops-task.git
  path: app/chart/olleh
  targetRevision: amir.prometheus
  helm:
    parameters:
      - name: replicaCount
        value: '3'
      - name: ingress.enabled
        value: 'true'
      - name: rollout.enabled
        value: 'true'
      - name: image.tag
        value: alpha
destination:
  server: https://kubernetes.default.svc
  namespace: olleh
syncPolicy:
  automated: {}
  syncOptions:
    - CreateNamespace=true
```

This will create an Argo Rollout runnin 3 instances of our sample app.

![olleh](/docs/img/argocd-olleh.png)

![alpha](/docs/img/alpha.png)
![alpha-preview](/docs/img/alpha-preview.png)

We can check if the logs and traces show up in Grafana:

![logs](/docs/img/olleh-logs.png)
![logstotraces](/docs/img/olleh-logs-correlations.png)
![traces](/docs/img/olleh-traces.png)
![servicemap](/docs/img/olleh-service-map.png)

Let's now update the image tag to `bravo`:

![update](/docs/img/argocd-update.png)

It'll create another replicaset, replicas of which are available through the preview service and ingress:

![rollout](/docs/img/argocd-rollout.png)

![alpha](/docs/img/alpha.png)
![bravo-preview](/docs/img/bravo-preview.png)

Our strategy is designed to pause the promotion to the newer version, so once the new replicaset is healthy, we'll be able to promote or drop the new version.

![promote](/docs/img/argocd-promote.png)

After full promotion, the new version will be available under http://hello.devops-task:32080/

![bravo](/docs/img/bravo.png)


### Regrets
Initially I planned to setup Argo Events and Argo Workflows to build the sample app images continuously on the Minikube itself.  Unfortunately I was short in time due to my travel to USA to attend KubeCon & CloudNativeCon NA 2025.  I had no other choice than to imitate the CI with an ansible playbook.  Peachy greetings from Atlanta :). 
#!/bin/bash

set -e
set -o errtrace
set -o pipefail

[[ $EUID -eq 0 ]] || { echo "this script requires root privileges"; exit 1; }

apt update && apt upgrade -y
apt install -y git ansible

git clone https://github.com/Amirbekyan/devops-task.git
cd devops-task

ansible-playbook -i localhost src/ansible-minikube.yml

[[ -f "terraform.tfvars" ]] || cp terraform.tfvars.sample terraform.tfvars

tofu init
tofu apply -auto-approve

ansible-playbook -i localhost src/ansible-docker-build.yml

printf "%s\t%s\n" "localhost" "preview.hello.devops-task hello.devops-task argocd.devops-task grafana.devops-task alert.devops-task prometheus.devops-task" >> /etc/hosts

echo "Setup completed successfully!"
echo "Check the usage doc for further instructions: https://github.com/Amirbekyan/devops-task/tree/amir.prometheus?tab=readme-ov-file#usage"

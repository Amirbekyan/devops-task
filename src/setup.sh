#!/bin/bash

apt update && apt upgrade -y
apt install -y git ansible

git clone https://github.com/Amirbekyan/devops-task.git
cd devops-task

ansible-playbook -i localhost src/ansible-minikube.yml

cp terraform.tfvars.sample terraform.tfvars

tofu init
tofu apply -auto-approve

ansible-playbook -i localhost src/ansible-docker-build.yml

printf "%s\t%s\n" "localhost" "preview.hello.devops-task hello.devops-task argocd.devops-task grafana.devops-task alert.devops-task prometheus.devops-task" >> /etc/hosts

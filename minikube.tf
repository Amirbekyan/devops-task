resource "null_resource" "minikube" {
  provisioner "local-exec" {
    command = "ansible-playbook -i localhost ${path.module}/src/ansible-minikube.yml"
  }
}

## will replace ansible-minikube.yml L219:228
# resource "kubernetes_namespace" "tigera_operator" {
#   metadata {
#     name = "tigera-operator"
#   }
# }

# resource "helm_release" "tigera_operator" {
#   name       = "tigera-operator"
#   repository = "https://docs.tigera.io/calico/charts"
#   chart      = "tigera-operator"
#   version    = "v3.31.0"
#   namespace  = kubernetes_namespace.tigera_operator.id

#   values = []
# }

# https://raw.githubusercontent.com/projectcalico/calico/v3.31.0/manifests/custom-resources.yaml
# resource "helm_release" "calico" {
#   name      = "calico"
#   chart     = "${path.module}/src/helm/calico"
#   namespace = kubernetes_namespace.tigera_operator.id

#   values = []
# }

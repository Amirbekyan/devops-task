resource "kubernetes_namespace" "olleh" {
  metadata {
    name = "olleh"
  }
}

# resource "helm_release" "olleh" {
#   name      = "olleh"
#   chart     = "${path.module}/app/chart/olleh"
#   namespace = kubernetes_namespace.olleh.id

#   set = [
#     {
#       name  = "nginxConfs"
#       value = "linksrc/*.conf"
#     },
#     {
#       name  = "ingress.enabled"
#       value = true
#     }
#   ]
# }

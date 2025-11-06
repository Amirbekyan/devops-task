locals {
  argocd = {
    namespace_name = "argocd"
    values_tpl     = "${path.module}/src/helm/argocd-values-tpl.yml"
    global_domain  = "argocd.devops-task"
    dex_image      = "v2.44.0"
    redis_image    = "8.2.2-alpine"
    redis_exporter = "v1.80.0"
    config_repositories = {
      # helm-charts = {
      #   type = "helm"
      #   name = "helm-charts"
      #   url  = "https://raw.githubusercontent.com/amirbekyan/helm-charts/gh-pages"
      #   # enableOCI = "false"
      #   username = var.github.user
      #   password = var.github.pat
      # }
      # gitops = {
      #   type     = "git"
      #   name     = "gitops"
      #   url      = "https://github.com/amirbekyan/gitops.git"
      #   username = var.github.user
      #   password = var.github.pat
      # }
      git = {
        type     = "git"
        name     = "devops-task"
        url      = "https://github.com/amirbekyan/devops-task.git"
        username = var.github.user
        password = var.github.pat
      }
    }
    env                   = "devops-task"
    notifications_enabled = false
    slack_channel         = "var.argocd_notifications.channel"
    slack_oauth_token     = "var.argocd_notifications.oauth_token"
    prometheus_enabled    = true
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = local.argocd.namespace_name
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = kubernetes_namespace.argocd.id
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.8.10"

  values = [
    templatefile(local.argocd.values_tpl, {
      global_domain         = local.argocd.global_domain
      config_repositories   = indent(4, yamlencode(local.argocd.config_repositories))
      dex_image             = local.argocd.dex_image
      redis_image           = local.argocd.redis_image
      redis_exporter        = local.argocd.redis_exporter
      env                   = local.argocd.env
      notifications_enabled = local.argocd.notifications_enabled
      slack_channel         = local.argocd.slack_channel
      slack_oauth_token     = local.argocd.slack_oauth_token
      prometheus_enabled    = local.argocd.prometheus_enabled
      prometheus_labels = indent(8, yamlencode({
        release = "prometheus"
      }))
    })
  ]
}

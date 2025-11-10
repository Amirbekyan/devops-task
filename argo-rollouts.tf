locals {
  argo_rollouts = {
    namespace_name        = "argo-rollouts"
    values_tpl            = "${path.module}/src/helm/argo-rollouts-values-tpl.yml"
    env                   = "devops-task"
    notifications_enabled = false
    slack_channel         = "var.argocd_notifications.channel"
    slack_oauth_token     = "var.argocd_notifications.oauth_token"
    prometheus_enabled    = true
  }
}

resource "kubernetes_namespace" "argo_rollouts" {
  metadata {
    name = local.argo_rollouts.namespace_name
  }

  depends_on = [helm_release.argocd]
}

resource "helm_release" "argo_rollouts" {
  name       = "argo-rollouts"
  namespace  = kubernetes_namespace.argo_rollouts.id
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-rollouts"
  version    = "2.38.0"

  values = [
    templatefile(local.argo_rollouts.values_tpl, {
      env                   = local.argo_rollouts.env
      notifications_enabled = local.argo_rollouts.notifications_enabled
      slack_channel         = local.argo_rollouts.slack_channel
      slack_oauth_token     = local.argo_rollouts.slack_oauth_token
      prometheus_enabled    = local.argo_rollouts.prometheus_enabled
      prometheus_labels = indent(8, yamlencode({
        release = "prometheus"
      }))
    })
  ]
}

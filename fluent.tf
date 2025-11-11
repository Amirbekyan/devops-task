locals {
  fluent = {
    namespace_name             = "fluent"
    fluent_operator_version    = "3.2.0"
    fluent_operator_values_tpl = "${path.module}/src/helm/fluent-operator-values-tpl.yml"
    fluentbit_version          = "3.1.7"
    fluentbit_values_tpl       = "${path.module}/src/helm/fluentbit-values-tpl.yml"
    cluster_name               = "devops-task"
    excludes = [
      "/var/log/containers/*_fluent_*.log",
      "/var/log/containers/*_argocd_*.log",
      "/var/log/containers/*_prometheus_*.log",
      "/var/log/containers/*_kube-system_*.log",
      "/var/log/containers/*_kube-node-lease_*.log",
      "/var/log/containers/*_kube-public_*.log",
      "/var/log/containers/*_metrics-server_*.log",
    ]
    loki_host = "loki.prometheus"
    loki_port = 3100
  }
}

resource "kubernetes_namespace" "fluent" {
  metadata {
    name = local.fluent.namespace_name
  }
  depends_on = [helm_release.prometheus]
}

resource "helm_release" "fluent_operator" {
  name       = "fluent-operator"
  chart      = "fluent-operator"
  repository = "https://fluent.github.io/helm-charts"
  namespace  = kubernetes_namespace.fluent.id
  version    = local.fluent.fluent_operator_version

  values = [
    templatefile(local.fluent.fluent_operator_values_tpl, {
      version = format("v%s", local.fluent.fluent_operator_version)
    })
  ]
}

resource "kubernetes_secret" "loki_auth" {
  metadata {
    name      = "loki-auth"
    namespace = kubernetes_namespace.fluent.id
  }
  data = {
    id = split(".", local.fluent.cluster_name)[0]
  }
}

resource "helm_release" "fluentbit" {
  name      = "fluentbit"
  chart     = "${path.module}/src/charts/fluentbit"
  namespace = helm_release.fluent_operator.namespace

  values = [
    templatefile(local.fluent.fluentbit_values_tpl, {
      version          = format("%s:v%s", "ghcr.io/fluent/fluent-operator/fluent-bit", local.fluent.fluentbit_version)
      exclude_paths    = join(",", local.fluent.excludes)
      loki_host        = local.fluent.loki_host
      loki_port        = local.fluent.loki_port
      loki_auth_secret = kubernetes_secret.loki_auth.metadata[0].name
      labels = indent(10, yamlencode([
        "cluster=${local.fluent.cluster_name}"
      ]))
      prometheus_labels = indent(4, yamlencode({
        "release" = "prometheus"
      }))
    })
  ]
}

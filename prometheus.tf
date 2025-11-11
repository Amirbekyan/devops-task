locals {
  prometheus = {
    namespace_name                = "prometheus"
    kube_prom_stack_chart_version = "75.9.0"
    kube_prom_stack_values_tpl    = "${path.module}/src/helm/prometheus-values-tpl.yml"

    prom_operator_version            = "v0.83.0"
    webhook_certgen_version          = "v1.6.0"
    cluster_domain                   = "cluster.local"
    prom_operator_clean_object_names = true

    prometheus_version               = "v3.4.2"
    prometheus_external_label        = "devops-task"
    prometheus_external_url          = "http://prometheus.devops-task"
    prometheus_enable_remote_write   = true
    prometheus_retention             = "10d"
    prometheus_pv_size               = "20Gi"
    prometheus_sa_annotations        = indent(4, yamlencode({}))
    prometheus_alertmanager_scheme   = "http"
    prometheus_alertmanager_endpoint = "prometheus-alertmanager:9093"
    prometheus_alertmanager_user     = ""
    prometheus_alertmanager_pass     = ""

    alertmanager_enabled      = true
    alertmanager_version      = "v0.28.1"
    alertmanager_external_url = "http://alert.devops-task"
    alertmanager_config_tpl   = "${path.module}/src/helm/alertmanager-config-tpl.yml"
    alertmanager_config_params = {
      mgmt = {
        url = var.webhook_url.mgmt
      }
      dev = {
        url = var.webhook_url.dev
      }
      stg = {
        url = var.webhook_url.stg
      }
      prod = {
        url = var.webhook_url.prod
      }
    }

    grafana_enabled              = true
    grafana_dashboard_configmaps = false
    grafana_pass                 = "grafanunu"
    grafana_ini = {
      analytics = {
        check_for_updates = true
      }
      loki = {
        http_client_timeout = "310s"
      }
      auth = {
        disable_login_form = false
      }
      "auth.anonymous" = {
        enabled  = true
        org_role = "Editor"
      }
    }
    grafana_folder_annotation       = "grafana_folder"
    grafana_k8s_dashboards_folder   = "K8s"
    grafana_default_datasource_uid  = "prometheus"
    grafana_default_datasource_name = "Prometheus"
    grafana_default_datasource_url  = "http://prometheus-prometheus:9090"
    grafana_default_datasource_type = "prometheus"
    grafana_dashboards = {
      logs = {
        loki      = "loki_rev1"
        loki_log  = "loki-log_rev2"
        fluentbit = "fluentbit_rev1" # https://docs.fluentbit.io/manual/administration/monitoring#grafana-dashboard-and-alerts
      }
      argocd = {
        argocd_official      = "argocd-official_rev1"      # https://grafana.com/grafana/dashboards/14584-argocd/
        argocd_operational   = "argocd-operational_rev4"   # https://grafana.com/grafana/dashboards/19993-argocd-operational-overview/
        argocd_applications  = "argocd-applications_rev4"  # https://grafana.com/grafana/dashboards/19974-argocd-application-overview/
        argocd_notifications = "argocd-notifications_rev4" # https://grafana.com/grafana/dashboards/19975-argocd-notifications-overview/
      }
      ingress = {
        ingress_nginx        = "ingress-nginx-overview_rev3" # https://grafana.com/grafana/dashboards/16677-ingress-nginx-overview/
        ingress_nginx_rhp    = "ingress-nginx-rhp_rev2"      # https://grafana.com/grafana/dashboards/20510-ingress-nginx-request-handling-performance/
        ingress_nginx_status = "ingress-nginx-status_rev1"   # https://grafana.com/grafana/dashboards/20275-ingress-nginx-dashboard/
        ingress_nginx_misc   = "ingress-nginx-misc_rev1"     # https://grafana.com/grafana/dashboards/21336-nginx-ingress-controller/
      }
    }
  }
}

resource "kubernetes_namespace" "prometheus" {
  metadata {
    name = local.prometheus.namespace_name
  }

  depends_on = [null_resource.wait_for_minikube]
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  chart      = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  namespace  = kubernetes_namespace.prometheus.id
  version    = local.prometheus.kube_prom_stack_chart_version

  values = [
    templatefile(local.prometheus.kube_prom_stack_values_tpl, {
      prometheus_labels = yamlencode({
        release = "prometheus"
      })

      prom_operator_version            = local.prometheus.prom_operator_version
      webhook_certgen_version          = local.prometheus.webhook_certgen_version
      cluster_domain                   = local.prometheus.cluster_domain
      prom_operator_clean_object_names = local.prometheus.prom_operator_clean_object_names

      prometheus_version                = local.prometheus.prometheus_version
      prometheus_replicas               = 1
      prometheus_sa_annotations         = local.prometheus.prometheus_sa_annotations
      prometheus_external_label         = local.prometheus.prometheus_external_label
      prometheus_external_url           = local.prometheus.prometheus_external_url
      prometheus_enable_remote_write    = local.prometheus.prometheus_enable_remote_write
      prometheus_disable_compaction     = true
      prometheus_clear_replica_label    = true
      prometheus_clear_prometheus_label = true
      prometheus_retention              = local.prometheus.prometheus_retention
      prometheus_pv_size                = local.prometheus.prometheus_pv_size
      prometheus_storage_class          = "standard"
      prometheus_priority_class         = "system-cluster-critical"
      prometheus_alertmanager_scheme    = local.prometheus.prometheus_alertmanager_scheme
      prometheus_alertmanager_endpoint  = local.prometheus.prometheus_alertmanager_endpoint
      prometheus_alertmanager_user      = local.prometheus.prometheus_alertmanager_user
      prometheus_alertmanager_pass      = local.prometheus.prometheus_alertmanager_pass

      alertmanager              = local.prometheus.alertmanager_enabled
      alertmanager_version      = local.prometheus.alertmanager_version
      alertmanager_external_url = local.prometheus.alertmanager_external_url
      alertmanager_config       = local.prometheus.alertmanager_config_tpl != "" ? kubernetes_secret.alertmanager_config[0].metadata[0].name : ""

      grafana                         = local.prometheus.grafana_enabled
      grafana_dashboard_configmaps    = local.prometheus.grafana_dashboard_configmaps
      grafana_pass                    = local.prometheus.grafana_pass
      grafana_ini                     = indent(4, yamlencode(local.prometheus.grafana_ini))
      grafana_folder_annotation       = local.prometheus.grafana_folder_annotation
      grafana_k8s_dashboards_folder   = local.prometheus.grafana_k8s_dashboards_folder
      grafana_default_datasource_uid  = local.prometheus.grafana_default_datasource_uid
      grafana_default_datasource_name = local.prometheus.grafana_default_datasource_name
      grafana_default_datasource_url  = local.prometheus.grafana_default_datasource_url
      grafana_default_datasource_type = local.prometheus.grafana_default_datasource_type
      grafana_additional_datasources = indent(4, yamlencode(concat(
        [
          {
            name   = "Loki"
            type   = "loki"
            uid    = "loki"
            access = "proxy"
            url    = "http://loki:3100"
            jsonData = {
              timeout  = 310
              maxLines = 1000
              derivedFields = [
                {
                  datasourceUid   = "tempo"
                  matcherType     = "label"
                  matcherRegex    = "trace_id"
                  name            = "TraceID"
                  url             = "$$${__value.raw}"
                  urlDisplayLabel = "View Trace"
                },
                {
                  datasourceUid   = "tempo"
                  matcherType     = "label"
                  matcherRegex    = "span_id"
                  name            = "SpanID"
                  url             = "{span:id=\"$$${__value.raw}\"}"
                  urlDisplayLabel = "View Span"
                }
              ]
            }
            editable = false
          }
        ],
        [
          {
            name = "Tempo"
            type = "tempo"
            uid  = "tempo"
            url  = "http://tempo:3200"
            jsonData = {
              tracesToLogsV2 = {
                datasourceUid      = "loki"
                spanStartTimeShift = "-1h"
                spanEndTimeShift   = "1h"
                tags = [
                  {
                    key   = "traceId"
                    value = "trace_id"
                  },
                  {
                    key   = "spanId"
                    value = "span_id"
                  },
                ]
                filterBySpanID  = false
                filterByTraceID = true
                customQuery     = true
                query           = "{$$__tags}"
              }
              tracesToMetrics = {
                datasourceUid      = local.prometheus.grafana_default_datasource_uid
                spanStartTimeShift = "-1h"
                spanEndTimeShift   = "1h"
                tags = [
                  {
                    key   = "service.name"
                    value = "service"
                  },
                  {
                    key   = "span.name"
                    value = "span_name"
                  },
                ]
                queries = [
                  {
                    name  = "Request rate"
                    query = "sum(rate(traces_spanmetrics_latency_bucket{$$__tags}[5m]))"
                  },
                  {
                    name  = "Error rate"
                    query = "sum(rate(traces_spanmetrics_calls_total{status_code=~\"STATUS_CODE_ERROR|4..|5..\", $$__tags}[5m]))"
                  }
                ]
              }
              serviceMap = {
                datasourceUid = local.prometheus.grafana_default_datasource_uid
              }
              nodeGraph = {
                enabled = true
              }
              search = {
                hide = false
              }
              traceQuery = {
                timeShiftEnabled   = true
                spanStartTimeShift = "-1h"
                spanEndTimeShift   = "1h"
              }
              spanBar = {
                type = "Tag"
                tag  = "http.path"
              }
              streamingEnabled = {
                search = false
              }
            }
            editable = true
          }
        ],
      )))
    })
  ]
}

resource "kubernetes_config_map" "grafana_dashboard" {
  for_each = merge([
    for group, dash in local.prometheus.grafana_dashboards : {
      for name, path in dash : name => {
        path   = path
        folder = group
      }
    }
  ]...)
  metadata {
    name      = format("%s-dashboard", replace(each.value.path, "/_rev.*/", ""))
    namespace = kubernetes_namespace.prometheus.id
    labels = {
      grafana_dashboard = 1
    }
    annotations = {
      grafana_folder = each.value.folder == "general" ? "" : title(each.value.folder)
    }
  }
  data = {
    format("%s-dashboard.json", replace(each.value.path, "/_rev.*/", "")) = file("${path.module}/src/grafana-dashboards/${each.value.path}.json")
  }
}

resource "kubernetes_secret" "alertmanager_config" {
  count = local.prometheus.alertmanager_config_tpl != "" ? 1 : 0
  metadata {
    name      = "alertmanager-config"
    namespace = kubernetes_namespace.prometheus.id
  }
  data = {
    "alertmanager.yaml" = templatefile(local.prometheus.alertmanager_config_tpl, {
      webhook_creds = local.prometheus.alertmanager_config_params
    })
  }
}

resource "helm_release" "loki" {
  name       = "loki"
  chart      = "loki"
  repository = "https://grafana.github.io/helm-charts"
  namespace  = helm_release.prometheus.namespace
  version    = "5.36.3"

  values = [
    templatefile("${path.module}/src/helm/loki-values-tpl.yml", {
      cluster_domain     = "cluster.local"
      persistence_size   = "20Gi"
      storage_class      = "standard"
      auth_enabled       = false
      replicas           = 1
      storage_type       = "filesystem"
      prometheus_address = "http://prometheus:9090"
      grafana_folder     = "Loki"
    })
  ]
}

resource "helm_release" "tempo" {
  name       = "tempo"
  chart      = "tempo"
  repository = "https://grafana.github.io/helm-charts"
  namespace  = helm_release.prometheus.namespace
  version    = "1.23.2"

  values = [
    templatefile("${path.module}/src/helm/tempo-values-tpl.yml", {
      storage_type       = "local"
      persistence        = true
      persistence_size   = "20Gi"
      storage_class      = "standard"
      prometheus_enabled = true
      prometheus_labels = indent(4, yamlencode({
        release = "prometheus"
      }))
      metrics_generator_enabled = true
      metrics_remote_write_url  = "http://prometheus-prometheus.prometheus:9090/api/v1/write"
      multitenancy_enabled      = false
      tempo_query               = true
    })
  ]
}

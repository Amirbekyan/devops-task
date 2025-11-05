locals {
  ingress_nginx = {
    namespace_name             = "ingress-nginx"
    values_tpl                 = "${path.module}/src/helm/ingress-nginx-values-tpl.yml"
    chart_version              = "4.13.0"
    ingress_controller_version = "v1.13.0"
    opentelemetry_version      = "v20230721-3e2062ee5"
    webhook_version            = "v1.6.0"
    default_backend_version    = "1.5"
    max_replicas               = 3
    host_port_enabled          = false
    host_ports = {
      http  = 80
      https = 443
    }
    service_enabled = true
    service_type    = "NodePort"
    node_ports = {
      http  = 32080
      https = 32443
    }
    rate_limit = {
      per_server = {
        key   = "$server_name"
        size  = "10m"
        limit = 2500
        burst = 500
        delay = 250
      }
      per_ip = {
        key   = "$binary_remote_addr"
        size  = "10m"
        limit = 500
        burst = 500
        delay = 250
      }
    }
    conn_limit = {
      per_ip = {
        key   = "$binary_remote_addr"
        size  = "10m"
        limit = 10
      }
    }
    tcp_services = {
      # "10901" = "prometheus/prometheus-thanos-discovery:10901"
    }
    basic_auth = {
      # prometheus = {
      #   auth      = tolist([var.basic_auth.grafana])
      #   namespace = module.prometheus_platform.prometheus_namespace_id
      # }
    }
    ingresses = {
      # prometheus = {
      #   namespace = module.prometheus_worker_us.prometheus_namespace_id
      #   annotations = {
      #     "cert-manager.io/cluster-issuer"                   = "letsencrypt-production"
      #     "nginx.ingress.kubernetes.io/enable-opentelemetry" = true
      #   }
      #   host       = "prometheus.worker.us.staging.deeporigin.io"
      #   backend    = "prometheus-kube-prometheus-prometheus"
      #   port       = "9090"
      #   tls        = true
      #   basic_auth = "prometheus"
      # }
    }
    # otlp_collector_host = "opentelemetry-collector.opentelemetry"
    # otlp_collector_port = 4317
  }
}

resource "kubernetes_namespace" "ingress_nginx" {
  metadata {
    name = local.ingress_nginx.namespace_name
  }
}

resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress_nginx.id
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = local.ingress_nginx.chart_version

  values = [
    templatefile(local.ingress_nginx.values_tpl, {
      replicas                   = 1
      autoscaling_enabled        = true
      min_replicas               = 1
      max_replicas               = local.ingress_nginx.max_replicas
      external_traffic_policy    = "Local"
      host_port_enabled          = local.ingress_nginx.host_port_enabled
      host_ports                 = local.ingress_nginx.host_ports
      service_enabled            = local.ingress_nginx.service_enabled
      service_type               = local.ingress_nginx.service_type
      node_ports                 = local.ingress_nginx.node_ports
      opentelemetry_enabled      = true
      ingress_controller_version = local.ingress_nginx.ingress_controller_version
      opentelemetry_version      = local.ingress_nginx.opentelemetry_version
      webhook_version            = local.ingress_nginx.webhook_version
      default_backend_version    = local.ingress_nginx.default_backend_version
      annotation_validation      = false
      snippet_annotation         = true
      config = indent(4, yamlencode({
        annotations-risk-level = "Critical"
        # enable-opentelemetry              = "true"
        # opentelemetry-operation-name      = "HTTP $request_method $service_name $uri"
        # opentelemetry-trust-incoming-span = "true"
        # otel-sampler                      = "AlwaysOn"
        # otel-sampler-ratio                = "1.0"
        # otel-service-name                 = "ingress-nginx"
        # otlp-collector-host               = local.ingress_nginx.otlp_collector_host
        # otlp-collector-port               = local.ingress_nginx.otlp_collector_port
        log-format-escape-json = "true"
        log-format-upstream = jsonencode({
          remote_addr                     = "$remote_addr"
          remote_user                     = "$remote_user"
          time_local                      = "$time_local"
          request                         = "$request"
          body_bytes_sent                 = "$body_bytes_sent"
          http_referrer                   = "$http_referer"
          request_length                  = "$request_length"
          request_time                    = "$request_time"
          proxy_upstream_name             = "$proxy_upstream_name"
          proxy_alternative_upstream_name = "$proxy_alternative_upstream_name"
          upstream_addr                   = "$upstream_addr"
          upstream_response_length        = "$upstream_response_length"
          upstream_response_time          = "$upstream_response_time"
          upstream_status                 = "$upstream_status"
          req_id                          = "$req_id"
          x_forwarded_for                 = "$proxy_add_x_forwarded_for"
          server_protocol                 = "$server_protocol"
          args                            = "$args"
          request_uri                     = "$request_uri"
          service_name                    = "$service_name"
          # remote_addr                     = "$proxy_protocol_addr"
          # time                            = "$time_iso8601"
          # bytes_sent                      = "$bytes_sent"
          ## the below keys are matched with deeporigin apps logs keys
          method = "$request_method"
          # trace_id  = "$opentelemetry_trace_id"
          # span_id   = "$opentelemetry_span_id"
          url       = "$uri"
          userAgent = "$http_user_agent"
          status    = "$status"
          host      = "$host"
          app       = "ingress-nginx"
        })
        http-snippet = join("\n",
          [
            for zone, param in local.ingress_nginx.rate_limit : format(
              "limit_req_zone %s zone=%s:%s rate=%dr/s;\nlimit_req zone=%s %s %s;",
              param.key,
              format("globalreq%s", replace(zone, "_", "")),
              param.size,
              param.limit,
              format("globalreq%s", replace(zone, "_", "")),
              can(param.burst) ? format("burst=%d", param.burst) : "",
              can(param.delay) ? param.delay == "0" ? "nodelay" : format("delay=%d", param.delay) : ""
            )
          ],
          [
            for zone, param in local.ingress_nginx.conn_limit : format(
              "limit_conn_zone %s zone=%s:%s;\nlimit_conn %s %s;",
              param.key,
              format("globalconn%s", replace(zone, "_", "")),
              param.size,
              format("globalconn%s", replace(zone, "_", "")),
              param.limit
            )
          ],
        )
      }))
      tcp_services = indent(2, yamlencode(local.ingress_nginx.tcp_services))
      # prometheus_enabled = true
      prometheus_enabled = false
      prometheus_labels = indent(8, yamlencode({
        release = "prometheus"
      }))
    })
  ]
}

resource "kubernetes_secret" "basic_auth" {
  for_each = local.ingress_nginx.basic_auth
  metadata {
    name      = "basic-auth-${each.key}"
    namespace = each.value.namespace
  }
  data = {
    auth = join("\n", [
      for cred in each.value.auth : "${cred.user}:${bcrypt(cred.pass)}"
    ])
  }
}

resource "kubernetes_manifest" "ingress" {
  for_each = local.ingress_nginx.ingresses
  manifest = {
    "apiVersion" = "networking.k8s.io/v1"
    "kind"       = "Ingress"
    "metadata" = {
      "name"      = each.key
      "namespace" = each.value.namespace
      "annotations" = merge(
        each.value.annotations,
        {
          "kubernetes.io/ingress.class" = "nginx"
        },
        each.value.basic_auth != null ? {
          "nginx.ingress.kubernetes.io/auth-type"   = "basic"
          "nginx.ingress.kubernetes.io/auth-secret" = kubernetes_secret.basic_auth[each.value.basic_auth].metadata[0].name
          "nginx.ingress.kubernetes.io/auth-realm"  = "DeepOrigin"
        } : {}
      )
    }
    "spec" = {
      "tls" = try(each.value.tls, true) ? [{
        "secretName" = "${each.key}-tls"
        "hosts"      = [each.value.host]
      }] : null
      "rules" = [{
        "host" = each.value.host
        "http" = {
          "paths" = concat([{
            "path"     = "/"
            "pathType" = "ImplementationSpecific"
            "backend" = {
              "service" = {
                "name" = each.value.backend
                "port" = {
                  "number" = each.value.port
                }
              }
            }
          }], try(each.value.additional_paths, []))
        }
      }]
    }
  }
}

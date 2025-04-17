data "aws_eks_cluster" "this" { name = var.cluster_name }
data "aws_eks_cluster_auth" "this" { name = var.cluster_name }


# Namespace
resource "kubernetes_namespace" "monitoring" {
  metadata { name = "monitoring" }
}

# AWS Load Balancer Controller (IRSA + Helm chart)
# ── new block in root main.tf  (place after the OIDC resource) ──────────
module "lb_controller" {
  source = "git::https://github.com/DNXLabs/terraform-aws-eks-lb-controller.git"                   

  # required
  cluster_name                        = data.aws_eks_cluster.this.name
  cluster_identity_oidc_issuer        = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
  cluster_identity_oidc_issuer_arn    = var.oidc
  service_account_name                = "aws-load-balancer-controller"
  settings = {
  region = var.region
  vpcId  = var.vpc_id
  }
  tags                                = var.tags
}



# kube‑prometheus‑stack
resource "helm_release" "kps" {
  name       = "kube-prom-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "70.7.0"
  timeout    = 900
  cleanup_on_fail = true
  values = [
  yamlencode({
    grafana = {
      adminPassword = var.grafana_admin_password

      service = {
        type       = "ClusterIP"
        port       = 3000
        targetPort = 3000
      }

      ingress = {
        enabled  = true
        ingressClassName = "alb"
        annotations = {
          "kubernetes.io/ingress.class"        = "alb"
          "alb.ingress.kubernetes.io/scheme"   = "internet-facing"
          "alb.ingress.kubernetes.io/target-type"  = "ip"
          "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\":3000}]"
        }
        hosts       = var.grafana_domain != "" ? [var.grafana_domain] : []
        path        = "/"
        pathType    = "Prefix"
        servicePort = 3000
      }

      sidecar = { dashboards = { enabled = true } }
    }
  })
]

  depends_on = [module.lb_controller]
}

# Ship any JSON dashboards dropped in dashboards/ dir
locals {
  dashboards = fileset("${path.module}/dashboards", "*.json")
}

resource "kubernetes_config_map" "dashboards" {
  for_each = { for f in local.dashboards : f => file("${path.module}/dashboards/${f}") }

  metadata {
    name      = replace(each.key, ".json", "")
    namespace = kubernetes_namespace.monitoring.metadata[0].name
    labels = {
      grafana_dashboard = "1"
    }
  }

  data = {
    "${each.key}" = each.value
  }
}

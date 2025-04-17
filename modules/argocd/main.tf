variable "tags" { type = map(string) }

resource "kubernetes_namespace" "argocd" {
  metadata { name = "argocd" }
}

resource "helm_release" "argocd" {
  name       = "argo-cd"
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "7.8.26"

  timeout    = 600
  wait       = true

  # Expose Argo via ALB on /
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }
  set {
    name  = "server.ingress.enabled"
    value = "true"
  }
  set {
    name  = "server.ingress.ingressClassName"
    value = "alb"
  }
  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
    value = "internet-facing"
  }
}

resource "kubernetes_manifest" "hello_nginx_app" {
  provider = kubernetes.eks

  manifest = yamldecode(file("${path.module}/../../apps/hello-nginx-app.yaml"))

  depends_on = [helm_release.argocd]
}
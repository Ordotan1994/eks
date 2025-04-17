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
  # ---------------- service ----------------
  set {
    name  = "server.service.type"
    value = "ClusterIP"
  }
  set { 
    name  = "server.service.port"
    value = "80"
  }     
  set { 
    name  = "server.service.targetPort"
    value = "8080"
  }  

  # ---------------- ingress ----------------
  set {
    name  = "server.ingress.enabled"
    value = "true"
  }
  set {
    name  = "server.ingress.ingressClassName"
    value = "alb"
  }
  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/listen-ports"
    value = "[{\"HTTP\":80}]"
  }
  set {
    name  = "server.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
    value = "internet-facing"
  }
  set { 
    name  = "server.ingress.servicePort"
    value = "80"
  }   

}

resource "kubernetes_manifest" "hello_nginx_app" {

  manifest = yamldecode(file("${path.module}/../../apps/hello-nginx-app.yaml"))

  depends_on = [helm_release.argocd]
}

/*
resource "helm_release" "argocd_crds" {
  name       = "argocd-crds"
  namespace  = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argocd-crds"
  version    = "7.8.26"

  create_namespace = true
  timeout  = 300
  wait     = true

}
*/


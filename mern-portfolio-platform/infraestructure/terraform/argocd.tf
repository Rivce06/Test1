resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"

  version = "10.1.4"

  namespace = kubernetes_namespace.argocd.metadata[0].name
}
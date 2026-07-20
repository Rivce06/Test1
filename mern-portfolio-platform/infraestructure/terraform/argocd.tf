resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = var.argocd_repo
  chart            = "argo-cd"
  version          = var.argocd_chart_version

  namespace        = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false

  wait = true
}
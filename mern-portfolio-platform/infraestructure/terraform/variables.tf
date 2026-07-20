variable "argocd_namespace" {
  description = "ArgoCd Namespace."
  type        = string
  default     = "argocd"
}

variable "argocd_chart_version" {
  description = "Argo CD Helm chart version."
  type        = string
}

variable "argocd_repo" {
  description = "Official Argo CD Helm repository."
  type        = string
}
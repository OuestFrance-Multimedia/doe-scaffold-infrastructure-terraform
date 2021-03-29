variable "cluster" {
  description = "enable or disable cluster"
  type        = bool
  default     = true
}

variable "environments_restricted" {
  type    = list(string)
  default = ["app-a-production", "app-a-preproduction"]
}

variable "environments_unrestricted" {
  type    = list(string)
  default = ["app-a-recette", "app-a-development"]
}

variable "apps" {
  type = list(object({ name = string, helm_values_files = list }))
  default = [
    {
      name              = "app-a",
      helm_values_files = ["production", "preproduction", "recette", "development"],
    },
  ]
}

variable "prometheus" {
  type = object({ enable = bool, kube_prometheus_stack_version = string, prometheus_adapter_version = string })
  default = {
    enable                        = true
    kube_prometheus_stack_version = "latest"
    prometheus_adapter_version    = "latest"
  }
}

variable "argocd" {
  type = object({ enable = bool, argocd_version = string, ingress = bool })
  default = {
    enable         = true
    argocd_version = "latest"
    ingress        = false
  }
}

locals {
  cluster = true
  environments_prod = [
    "app-a-production",
    "app-a-preproduction"
  ]
  environments_noprod = [
    "app-a-recette",
    "app-a-development"
  ]
  apps = [
    {
      name              = "app-a",
      helm_values_files = ["production", "preproduction", "recette", "development"],
    },
  ]
  prometheus = {
    enable                        = true
    kube_prometheus_stack_version = "latest"
    prometheus_adapter_version    = "latest"
  }
  argocd = {
    enable         = true
    argocd_version = "latest"
    ingress        = false
  }
}

module "gitlab-repos" {
  source    = "./modules/additi-gitlab"
  full_path = ""       # the path where content-app and platform-helm will be created (e.g. `additi/internal/dsi-devops-engineers`)
  projects  = var.apps # Gitlab content-app and platform-helm repo to create
}

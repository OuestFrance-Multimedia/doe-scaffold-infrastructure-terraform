module "gitlab-projects" {
  source    = "./modules/additi-gitlab"
  full_path = ""       # the path where content-app and platform-helm will be created (e.g. `additi/internal/dsi-devops-engineers`)
  projects  = var.apps # Gitlab content-app and platform-helm repo to create
}

module "additi-gitlab" {
  source = "./modules/additi-gitlab"

  full_path = ""                                                                   # the path where content-app and platform-helm will be created (e.g. `additi/internal/dsi-devops-engineers`)

  projects = [                                                                     # Gitlab content-app and platform-helm repo to create
    {
      name            = ""                                                         # Application name (e.g `sample-project`)
    },
  ]
}

module "additi-project-factory" {
  source = "./modules/additi-project-factory"
  gcp_org_id          = ""                                                          # gcloud organizations list
  gcp_billing_account = ""                                                          # gcloud beta billing accounts list
  gcp_project         = ""                                                          # name of the GCP project to create (e.g. group-production)
  cidr_prefix         = ""                                                          # the platform cidr prefix `/16` (e.g. 10.13) refer to documentation to pick unattribued prefix

  members = [
    ""                                                                              # GCP IAM members (e.g. group:foo@domain.fr)
  ]

  # Liste des projets gitlabci dans lesquels on va :
  # - affecter dans une variable d'environnement que l'on définit la valeur clé du compte de service 
  # - affecter dans une variable d'environnement que l'on définit la valeur de l'url de la registry 
  # pré-requis : terraform apply -target 'module.additi-gitlab' -auto-approve

  gitlabci_projects = [
    {
      project = module.additi-gitlab.gitlab_project.code_repos["content-app-name"].id,   # replace `content-app-name` by the application name (line 8)
      key_google_app_creds = "",                                                         # GOOGLE_APPLICATION_CREDENTIALS + suffix SHOULD match line 17 (gcp_project)
      key_repository = ""                                                                # REPOSITORY_GROUP + suffix SHOULD match line 17 (gcp_project)
    },
  ]

  platforms = [                # = namespaces
    "preproduction",           # preproduction are handled like productions
    "production"
  ]

  common_authorized_networks = [
    { cidr_block = "8.8.8.8/24", display_name = "sample" }, # Authorized networks allowed to connect to ressources
  ]

  # kubernetes_version = "latest"  # This is the default behaviour
  # release_channel = "STABLE"     # This is the default behaviour

  node_pools = [{
    name                        = "stoic_swirles"
    disk_type                   = "pd-standard"
    image_type                  = "COS"                 # GKE strongly advise you to use COS image type
    machine_type                = "n2-standard-2"
    min_count                   = 2
    max_count                   = 4
  }]

  prometheus  = {
    enable                        = true
    kube_prometheus_stack_version = "latest" #"latest"
    prometheus_adapter_version    = "latest" #"latest"
  }
  argocd  = {
    enable                        = true
    argocd_version                = "latest" # "latest"
    ingress                       = false
  }
  longhorn    = false
}


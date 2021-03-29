locals {
  cluster = true
  platforms = [                       # -> namespaces
    "gifted-mclean-preproduction",
    "gifted-mclean-production"
  ]
  prometheus = {
    enable                        = true
    kube_prometheus_stack_version = "latest" #"latest"
    prometheus_adapter_version    = "latest" #"latest"
  }
  argocd = {
    enable         = true
    argocd_version = "latest" # "latest"
    ingress        = false
  }
}

module "additi-gitlab" {
  source = "./modules/additi-gitlab"

  full_path = "" # the path where content-app and platform-helm will be created (e.g. `additi/internal/dsi-devops-engineers`)

  projects = [ # Gitlab content-app and platform-helm repo to create
    {
      name = "" # Application name (e.g `gifted-mclean`)
    },
  ]
}

module "additi-project-factory" {
  source              = "./modules/additi-project-factory"
  gcp_org_id          = "" # gcloud organizations list
  gcp_billing_account = "" # gcloud beta billing accounts list
  gcp_project         = "" # name of the GCP project to create (e.g. group-common-prod)
  cidr_prefix         = "" # the platform cidr prefix `/16` (e.g. 10.13) refer to documentation to pick unattribued prefix

  members = [
    "" # GCP IAM members (e.g. group:foo@domain.fr)
  ]

  # Liste des projets gitlabci dans lesquels on va :
  # - affecter dans une variable d'environnement que l'on définit la valeur clé du compte de service 
  # - affecter dans une variable d'environnement que l'on définit la valeur de l'url de la registry 
  # pré-requis : terraform apply -target 'module.additi-gitlab' -auto-approve

  gitlabci_projects = [
    {
      project              = module.additi-gitlab.gitlab_project.code_repos["gifted-mclean"].id,    # replace `content-app-name` by the application name (line 8)
      key_google_app_creds = "",                                                                    # GOOGLE_APPLICATION_CREDENTIALS + suffix SHOULD match line 35 (gcp_project)
      key_repository       = ""                                                                     # REPOSITORY_GROUP + suffix SHOULD match line 35 (gcp_project)
    },
  ]

  platforms = local.platforms # = namespaces

  common_authorized_networks = [
    { cidr_block = "8.8.8.8/24", display_name = "sample" }, # Authorized networks allowed to connect to ressources
  ]

  # kubernetes_version = "latest"  # This is the default behaviour
  # release_channel = "STABLE"     # This is the default behaviour

  gke = local.cluster

  gke_cluster_name = "gifted-mclean"

  gke_node_pools = [{
    name         = "stoic-swirles"
    disk_type    = "pd-standard"
    image_type   = "COS" # GKE strongly advise you to use COS image type
    machine_type = "n2-standard-2"
    min_count    = 2
    max_count    = 4
  }]

  gke_node_pools_labels = [{
    "all" : {},
    "stoic-swirles" : {}
  }]

  gke_node_pools_metadata = [{
    "all" : {},
    "stoic-swirles" : {}
  }]

  gke_node_pools_oauth_scopes = [{
    "all" : [
      "https://www.googleapis.com/auth/cloud-platform"
    ],
    "stoic-swirles" : []
  }]

  gke_node_pools_tags = [{
    "all" : [],
    "stoic-swirles" : []
  }]

  gke_node_pools_taints = [{
    "all" : [],
    "stoic-swirles" : []
  }]

  sql_database_instances = [{ name = "db_instance_name", tier = "db-n1-standard-1" }]

  prometheus = local.prometheus
  argocd     = local.prometheus
}

module "additi-kubernetes" {
  source                        = "./modules/additi-kubernetes"
  cluster                       = local.cluster
  kubernetes_config             = module.additi-project-factory.kubernetes_config
  platforms                     = local.platforms
  cloudsql_proxy_sa_private_key = module.additi-project-factory.cloudsql_proxy_sa_private_key
  databases_credentials         = module.additi-project-factory.databases_credentials
  prometheus                    = local.prometheus
  argocd = merge(
    local.argocd,
    {
      admin_password   = module.additi-project-factory.module.project-factory.project_id
      load_balancer_ip = module.additi-project-factory.argocd.load_balancer_ip
      annotations      = module.additi-project-factory.argocd.annotations
    }
  )
  authorized_networks = module.additi-project-factory.authorized_networks
}

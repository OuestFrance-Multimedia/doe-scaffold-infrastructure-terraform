module "additi-project-factory-prod" {
  source              = "./modules/additi-project-factory"
  gcp_org_id          = "" # gcloud organizations list
  gcp_billing_account = "" # gcloud beta billing accounts list
  gcp_project         = "" # name of the GCP project to create (See confluence : /display/DSI/Provisionning)
  cidr_prefix         = "" # the platform cidr prefix `/16` (e.g. 10.13) refer to documentation to pick unattribued prefix

  members = [
    "" # ReadOnly GCP IAM members (e.g. group:foo@domain.fr)
  ]

  gitlabci_projects = [                                                                   # content-app gitlab projects to add secret ci-cd vars
    {
      project              = module.gitlab-projects.gitlab_project.code_repos["app-a"].id,
      key_google_app_creds = "GOOGLE_APPLICATION_CREDENTIALS-app-a",                      # GOOGLE_APPLICATION_CREDENTIALS + suffix SHOULD match line 35 (gcp_project)
      key_repository       = "REPOSITORY_GROUP-app-a"                                     # REPOSITORY_GROUP + suffix SHOULD match line 35 (gcp_project)
    },
  ]

  platforms = local.environments_prod

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

module "additi-kubernetes-prod" {
  source                        = "./modules/additi-kubernetes"
  cluster                       = local.cluster
  kubernetes_config             = module.additi-project-factory-prod.kubernetes_config
  platforms                     = local.environments_prod
  cloudsql_proxy_sa_private_key = module.additi-project-factory-prod.cloudsql_proxy_sa_private_key
  databases_credentials         = module.additi-project-factory-prod.databases_credentials
  prometheus                    = local.prometheus
  argocd = merge(
    local.argocd,
    {
      admin_password   = module.additi-project-factory-prod.module.project-factory.project_id
      load_balancer_ip = module.additi-project-factory-prod.argocd.load_balancer_ip
      annotations      = module.additi-project-factory-prod.argocd.annotations
    }
  )
  authorized_networks = module.additi-project-factory.authorized_networks
}

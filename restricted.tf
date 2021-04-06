module "additi-project-factory-restricted" {
  source = "./modules/additi-project-factory"
  gcp_org_id          = local.common.gcp_org_id
  gcp_billing_account = local.common.gcp_billing_account
  gcp_project         = "${local.common.gcp_project}-restricted"
  cidr_prefix         = local.common.cidr_prefix

  members = [
    ""                                                                      # Format "group:groupname@domain"
  ]

  platforms = local.infrastructures.restricted.platforms

  common_authorized_networks = [
    { cidr_block = "x.y.w.z/32", display_name = "custom IP" },
  ]

  sql_database_instances = []                                               # [{name = "foo",tier = "db-n1-standard-1"}] # [{name = "foo"}] or []

  gke = true

  gke_node_pools = [{
    name         = "stoic-swirles"                                          # ensure to report this name in the underlying lines
    disk_type    = "pd-standard"
    image_type   = "COS"                                                    # GKE strongly advise you to use COS image type
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
}

module "restricted-gitlab-variables" {
  source = "./modules/additi-gitlab-variables"
  
  variables   = local.variables.restricted
  projects    = module.gitlab.gitlab_project.code_repos
  suffix      = "restricted"
}

module "restricted-kubernetes" {
  source = "./modules/additi-kubernetes"
  cluster                         = true
  kubernetes_config               = module.restricted-project-factory.kubernetes_config
  platforms                       = local.infrastructures.restricted.platforms
  cloudsql_proxy_sa_private_key   = module.restricted-project-factory.google_application_credentials.cloudsql_proxy_sa_private_key
  databases_credentials           = module.restricted-project-factory.databases_credentials
  prometheus = { enable = false }
  argocd = {
    enable            = true
    ingress           = false
    load_balancer_ip  = module.restricted-project-factory.argocd.load_balancer_ip
    annotations       = module.restricted-project-factory.argocd.annotations
  }
  authorized_networks             = module.restricted-project-factory.authorized_networks
}

module "restricted-argocd" {
  source = "./modules/additi-argocd"

  server_addr     = "${module.restricted-project-factory.argocd.address}:443"
  password        = module.restricted-kubernetes.argocd.admin_password
  insecure        = true
  applications    = local.infrastructures.restricted.argocd.applications
  target_revision = local.infrastructures.restricted.argocd.target_revision
}
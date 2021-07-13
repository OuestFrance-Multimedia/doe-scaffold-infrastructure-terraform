module "unrestricted-project-factory" {
  source              = "./modules/additi-project-factory"
  gcp_org_id          = local.common.gcp_org_id
  gcp_folder_id       = local.unrestricted.gcp_folder_id
  gcp_billing_account = local.common.gcp_billing_account
  gcp_project         = "${local.common.gcp_project}-unrestricted"
  cidr_prefix         = local.common.cidr_prefix

  members = local.unrestricted.project_members

  developer_groups = []

  platforms = local.infrastructures.unrestricted.platforms

  common_authorized_networks = local.common.common_authorized_networks

  sql_database_instances = [] # [{name = "foo",tier = "db-n1-standard-1"}] # [{name = "foo"}] or []

  sql_database_instances_replica = [] # [{name = "foo",tier = "db-n1-standard-1", master_instance_name = "foo" }] # [{name = "foo"}] or []

  gke = true

  gke_node_pools = [{
    name         = "stoic-swirles" # ensure to report this name in the underlying lines
    disk_type    = "pd-standard"
    image_type   = "COS" # GKE strongly advise you to use COS image type
    machine_type = "n2-standard-2"
    preemptible  = true
    min_count    = 2
    max_count    = 4
  }]

  gke_node_pools_labels = {
    "all" : {},
    "stoic-swirles" : {}
  }

  gke_node_pools_metadata = {
    "all" : {},
    "stoic-swirles" : {}
  }

  gke_node_pools_oauth_scopes = {
    "all" : [
      "https://www.googleapis.com/auth/cloud-platform"
    ],
    "stoic-swirles" : []
  }

  gke_node_pools_tags = {
    "all" : [],
    "stoic-swirles" : []
  }

  gke_node_pools_taints = {
    "all" : [],
    "stoic-swirles" : []
  }
}

module "unrestricted-gitlab-variables" {
  source = "./modules/additi-gitlab-variables"

  variables = local.variables.unrestricted
  projects  = module.gitlab.gitlab_project.code_repos
  suffix    = "unrestricted"
}

module "unrestricted-kubernetes" {
  source                        = "./modules/additi-kubernetes"
  kubernetes_config             = module.unrestricted-project-factory.kubernetes_config
  platforms                     = local.infrastructures.unrestricted.platforms
  cloudsql_proxy_sa_private_key = module.unrestricted-project-factory.google_application_credentials.cloudsql_proxy_sa_private_key
  databases_credentials         = module.unrestricted-project-factory.databases_credentials
}

module "unrestricted-kube-prometheus-stack-with-grafana-install" {
  source                       = "./modules/additi-kube-prometheus-stack-with-grafana-install"
  kubernetes_config            = module.unrestricted-project-factory.kubernetes_config
  kube_prometheus_stack_values = <<-EOT
    grafana:
      service:
        loadBalancerIP: "${module.unrestricted-project-factory.grafana.load_balancer_ip}"
        loadBalancerSourceRanges:
        ${indent(4, yamlencode(module.unrestricted-project-factory.authorized_networks[*].cidr_block))}
        type: "LoadBalancer"
  EOT
}

module "unrestricted-loki" {
  source            = "./modules/additi-loki"
  kubernetes_config = module.unrestricted-project-factory.kubernetes_config
}

module "unrestricted-promtail" {
  source            = "./modules/additi-promtail"
  kubernetes_config = module.unrestricted-project-factory.kubernetes_config
}

module "unrestricted-grafana" {
  source = "./modules/additi-grafana"

  url      = "http://${module.unrestricted-project-factory.grafana.address}"
  username = "admin"
  password = module.unrestricted-kube-prometheus-stack-with-grafana-install.grafana.admin_password
}

module "unrestricted-argocd-install" {
  source            = "./modules/additi-argocd-install"
  kubernetes_config = module.unrestricted-project-factory.kubernetes_config

  argocd_values = <<-EOT
    repoServer:
      env:
      - name: ARGOCD_GIT_MODULES_ENABLED
        value: "false"
    server:
      service:
        type: "LoadBalancer"
        loadBalancerIP: "${module.unrestricted-project-factory.argocd.load_balancer_ip}"
        loadBalancerSourceRanges:
        ${indent(4, yamlencode(module.unrestricted-project-factory.authorized_networks[*].cidr_block))}
  EOT

  argocd_notifications_values = <<-EOT
    argocdUrl: https://${module.unrestricted-project-factory.argocd.load_balancer_ip}
  EOT

  teams_webhooks               = local.common.teams_webhooks.unrestricted
  api_key_argocd_notifications = module.unrestricted-grafana.api_key_argocd_notifications
}

module "unrestricted-argocd-config" {
  source = "./modules/additi-argocd-config"

  server_addr     = "${module.unrestricted-project-factory.argocd.address}:443"
  password        = module.unrestricted-argocd-install.argocd.admin_password
  insecure        = true
  applications    = local.infrastructures.unrestricted.argocd.applications
  target_revision = local.infrastructures.unrestricted.argocd.target_revision
}

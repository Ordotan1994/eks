module "network" {
  source        = "./modules/network"
  vpc_cidr      = var.vpc_cidr
  azs           = local.selected_azs
  public_cidrs  = var.public_cidrs
  private_cidrs = var.private_cidrs
  tags          = var.tags
  region        = var.region
  cluster_name = var.cluster_name
  security_group_ids = module.security.endpoints_sg_id
  ssm_endpoints = {
    eks = "com.amazonaws.${var.region}.eks"
    eks-auth = "com.amazonaws.${var.region}.eks-auth"
  }
}

module "security" {
  source               = "./modules/security"
  vpc_id               = module.network.vpc_id
  alb_sg_ingress_cidrs = ["0.0.0.0/0"]
  vpc_cidr             = var.vpc_cidr
  tags                 = var.tags
}

module "alb" {
  source      = "./modules/alb"
  vpc_id      = module.network.vpc_id
  subnet_ids  = module.network.public_subnet_ids
  alb_sg_id   = module.security.alb_sg_id
  target_port = 80
  tags        = var.tags
}

module "eks" {
  source             = "./modules/eks"
  cluster_name       = var.cluster_name
  vpc_id             = module.network.vpc_id
  subnet_ids         = module.network.private_subnet_ids
  cluster_sg_id      = module.security.eks_sg_id
  node_instance_type = var.node_instance_type
  desired_capacity   = var.desired_capacity
  min_capacity       = var.min_capacity
  max_capacity       = var.max_capacity
  alb_sg_id          = module.security.alb_sg_id
  tags               = var.tags
  depends_on = [ module.network, module.security ]
}


module "monitoring" {
  source                 = "./modules/monitoring"
  cluster_name           = var.cluster_name
  grafana_admin_password = var.grafana_admin_password
  grafana_domain         = var.grafana_domain
  tags                   = var.tags
  oidc                   = aws_iam_openid_connect_provider.oidc.arn
  vpc_id = module.network.vpc_id
  region = var.region

  providers = {
  kubernetes = kubernetes.eks
  helm       = helm.eks
  }

  depends_on = [module.eks]
}

module "autoscaler" {
  source       = "./modules/autoscaler"
  cluster_name = module.eks.cluster_name
  region       = var.region
  tags         = var.tags

  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }

  depends_on = [module.lb_controller]
}

module "argocd" {
  source    = "./modules/argocd"
  tags      = var.tags
  providers = {
    kubernetes = kubernetes.eks
    helm       = helm.eks
  }
}

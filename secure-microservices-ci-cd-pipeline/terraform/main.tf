provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  name    = "secure-vpc"
  cidr    = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.4" # or latest stable

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1

      instance_types = ["t3.medium"]
      subnet_ids     = module.vpc.private_subnets
    }
  }

  cluster_endpoint_public_access = false
  cluster_enabled_log_types      = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  iam_role_name_prefix = "eks-cluster-role"
  iam_role_additional_policies = {
    s3_readonly = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  }

  iam_role_service_accounts = {
    metrics_server = {
      namespace      = "kube-system"
      service_account = "metrics-server"
      attach_policy_arn = [
        "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
      ]
    },
    external_dns = {
      namespace      = "kube-system"
      service_account = "external-dns"
      attach_policy_arn = [
        "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
      ]
    },
    ebs_csi_controller = {
      namespace      = "kube-system"
      service_account = "ebs-csi-controller-sa"
      attach_policy_arn = [
        "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      ]
    },
    vault_auth = {
      namespace      = "vault"
      service_account = "vault-auth"
      attach_policy_arn = [
        "arn:aws:iam::aws:policy/AdministratorAccess"
      ]
    }
  }

  tags = {
    Environment = "secure-prod"
  }
}

# Vault Helm release for Kubernetes secrets integration
resource "helm_release" "vault" {
  name       = "vault"
  namespace  = "vault"
  repository = "https://helm.releases.hashicorp.com"
  chart      = "vault"
  version    = "0.27.0"

  create_namespace = true

  set {
    name  = "server.ha.enabled"
    value = "true"
  }

  set {
    name  = "injector.enabled"
    value = "true"
  }

  set {
    name  = "server.dataStorage.enabled"
    value = "true"
  }

  set {
    name  = "server.dev.enabled"
    value = "false"
  }

  values = [
    file("values/vault-values.yaml")
  ]
}

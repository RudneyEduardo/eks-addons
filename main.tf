locals{
  region = "us-east-1"
  vpc_name = "${local.org}-${local.account}"
  org = "ORG_NAME"
  stage_name = "STAGE"
  cluster_version = "1.28"
  instance_types = ["t4g.medium"]
  enable_2048_app = false # colocar como true para já subir o cluster com o 2048 
  tags = {
    stage = local.stage
  }
}


data "aws_vpc" "selected"{
  tags = {
    Name = local.vpc_name
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  tags = {
    "${local.org}/tier" = "private"
  }
}


data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}


locals {
  vpc_cidr = "10.11.0.0/16"
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.15.3"

  cluster_name                   = "${local.org}-${local.stage_name}-eks"
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  vpc_id     = data.aws_vpc.selected.id
  subnet_ids = data.aws_subnets.private.ids

  eks_managed_node_groups = {
    core_node_group = {
      instance_types = local.instance_types

      ami_type = "BOTTLEROCKET_x86_64"
      platform = "bottlerocket"

      min_size     = 3
      max_size     = 3
      desired_size = 3
    }
  }

  tags = local.tags
}


module "eks_blueprints_addons" {
  source = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0" 

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  enable_aws_load_balancer_controller    = true
  enable_metrics_server                  = true

  tags = {
    local.tags
  }
}

module {
   source = "./modules/app-2048"

   count = local.enable_2048_app ? 1 : 0
} 
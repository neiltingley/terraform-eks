terraform {
  required_version = ">= 1.5.1"

  required_providers {
    aws = {
      version = ">= 5.40.0"
      source  = "hashicorp/aws"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"

    }
    kubectl = {
      source  = "alekc/kubectl"
      version = ">= 2.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.5"
    }

    kubernetes = {
      version = ">= 2.17.0"
    }

  }

  backend "s3" {
    bucket = "thump-state-bucket"
    key = "state-provision"
    region = "eu-west-1"

  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = var.global_tags
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  #cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.demo-cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host = data.aws_eks_cluster.demo-cluster.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.demo-cluster.certificate_authority[0].data)
    #cluster_ca_certificate = = base64decode(data.aws_eks_cluster.demo_cluster.aws_eks_cluster"
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", "demo-cluster"]
      command     = "aws"
    }
  }
}

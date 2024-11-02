
variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "Target AWS region"
}

variable "eks_module_version" {
  type = string
  default = "20.27.0"
}
variable "cluster_name" {
  type        = string
  default     = "demo-cluster"
  description = "Name of the EKS cluster"
}


variable "global_tags" {
  type = map(string)
  default = {
    "ManagedBy"   = "Terraform"
    "Environment" = "dev"
  }
}

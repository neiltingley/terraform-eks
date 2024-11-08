
variable "region" {
  type        = string
  default     = "eu-west-1"
  description = "Target AWS region"
}

variable "cluster_name" {
  type        = string
  default     = "ex-karpenter-demo"
  description = "Name of the EKS cluster"
}
# variable "aws_account_number" {
#   type    = number
#   default = 
#   description = "AWS account number used for deployment."
# }

variable "global_tags" {
  type = map(string)
  default = {
    "ManagedBy"   = "Terraform"
    "Environment" = "dev"
  }
}

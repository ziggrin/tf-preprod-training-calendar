### Not finished
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # cloud { 
    
  #   organization = "smakslaska" 

  #   workspaces { 
  #     name = "vpc-omega" 
  #   } 
  # } 
}

provider "aws" {
  # access_key = data.vault_aws_access_credentials.aws_creds.access_key
  # secret_key = data.vault_aws_access_credentials.aws_creds.secret_key
  # token      = data.vault_aws_access_credentials.aws_creds.security_token
  region     = "eu-north-1"
}

# data "vault_aws_access_credentials" "aws_creds" {
#   backend = "aws/${var.aws_account}"
#   role    = "TerraformVaultRole"
#   region  = "eu-north-1"
#   type    = "sts"
# }

#Doc : https://developer.hashicorp.com/terraform/language/backend/s3

terraform {
  backend "s3" {
     bucket = "my-terraform-state-rani-2025"
     key    = "terraform.tfstate"
     region = "eu-north-1"
  }
}

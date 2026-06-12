terraform {
  backend "s3" {
    bucket         = "brijesh-terraform-state-bucket"
    key            = "devops-project/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
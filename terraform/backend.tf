terraform {
  backend "s3" {
    bucket         = "capstone-tf-state-1770806700"
    key            = "final-project/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

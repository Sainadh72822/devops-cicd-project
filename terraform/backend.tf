terraform {
  backend "s3" {
    bucket       = "devops-terraform-state-044014415078"
    key          = "devops-project/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}

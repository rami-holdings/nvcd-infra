terraform {
  backend "s3" {
    bucket         = "nvc-terraform-state-460742884765-usw2"
    key            = "envs/prod/nvcd-infra/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "nvc-terraform-locks-usw2"
    encrypt        = true
    kms_key_id     = "alias/nvc-terraform-backend"
  }
}

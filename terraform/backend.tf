terraform {
  backend "s3" {
    region         = "eu-west-2"
    encrypt        = true
    bucket         = "xc-tgw-vpc-terraform-state"
    dynamodb_table = "xc-tgw-vpc-terraform-locks"
    key            = "spp-cross-cutting-cognito-poc"
  }
}

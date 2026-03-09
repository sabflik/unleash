module "compute" {
  source = "./modules/compute"

  regions = [
    "us-east-1",
    "eu-west-1",
  ]

  cognito_user_pool_id = module.auth.user_pool_id
}

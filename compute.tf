module "compute" {
  source = "./modules/compute"

  cognito_user_pool_id = module.auth.user_pool_id
}

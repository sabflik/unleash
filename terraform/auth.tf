module "auth" {
  source = "./modules/auth"

  user_pool_name        = var.user_pool_name
  user_pool_client_name = var.user_pool_client_name
}

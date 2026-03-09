module "auth" {
  source = "./modules/auth"

  user_pool_name        = var.user_pool_name
  user_pool_client_name = var.user_pool_client_name
  test_user_email       = var.test_user_email
  test_user_password    = var.test_user_password
}

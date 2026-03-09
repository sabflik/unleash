module "compute" {
  source = "./modules/compute"

  # providers configuration to enable resources in multiple regions
  providers = {
    aws       = aws           # us-east-1
    aws.euw   = aws.euw       # eu-west-1
  }

  # pass variables here once defined by the module
}

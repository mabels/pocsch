module "prod-pocsch-car-list" {
  source = "./code_build"
  name = "prod-pocsch-car-list"
}

module "prod-prod-pocsch-service-list" {
  source = "./code_build"
  name = "prod-pocsch-service-list"
}

module "prod-prod-pocsch-user-info" {
  source = "./code_build"
  name = "prod-pocsch-user-info"
}

module "prod-prod-pocsch-ui" {
  source = "./code_build"
  name = "prod-pocsch-ui"
}


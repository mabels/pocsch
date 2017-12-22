module "ecs_prod" {
  source = "./ecs-cluster"
  name = "prod"
  max_size = 2
  services = "car-list,service-list,user-info,ui"
  asg_regions = ["eu-west-1b"]
}

module "ecs_stage" {
  source = "./ecs-cluster"
  name = "stage"
  services = "car-list,service-list,user-info,ui"
  asg_regions = ["eu-west-1b"]
}


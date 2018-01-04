module "ecs_stage_html" {
  source = "./ecs-service"
  project_name = "stage"
  service_name = "html"
  #depends_on = ["module.ecs_stage"]
  #depends_on = ["aws_s3_bucket.alb_logs"]
}
#
module "ecs_stage_car_list" {
  source = "./ecs-service"
  project_name = "stage"
  service_name = "carList"
  #depends_on = ["module.ecs_stage"]
  #depends_on = ["aws_s3_bucket.alb_logs"]
}


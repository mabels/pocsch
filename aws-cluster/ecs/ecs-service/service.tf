variable "project_name" {}
variable "service_name" {}

data "aws_vpc" "ecsClusterVpc" {
  tags { Name = "ecs-vpc-${var.project_name}" }
}


resource "aws_security_group" "ecsSecurityAlb" {
  name       = "node-sg-${var.project_name}-${var.service_name}"
  vpc_id     = "${data.aws_vpc.ecsClusterVpc.id}"
  tags {
    Name        = "ecs-sy-alb-${var.project_name}-${var.service_name}"
  }
}

resource "aws_security_group_rule" "ecsSecurityAlb" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ecsSecurityAlb.id}"
}

data "aws_subnet_ids" "byVpc" {
  vpc_id = "${data.aws_vpc.ecsClusterVpc.id}"
}

data "aws_s3_bucket" "alb_logs" {
  bucket = "ecs-alb-stage-logs"
}

resource "aws_lb" "ecsAlb" {
  name            = "ecs-alb-${var.project_name}-${var.service_name}"
  internal        = false
  security_groups = ["${aws_security_group.ecsSecurityAlb.id}"]
  subnets         = ["${data.aws_subnet_ids.byVpc.ids}"]

  enable_deletion_protection = false

  access_logs {
    bucket = "${data.aws_s3_bucket.alb_logs.bucket}"
    prefix = "${var.service_name}"
  }
  tags {
    Environment = "${var.project_name}"
  }
}

resource "aws_lb_target_group" "ecsAlb" {
  name     = "ecs-tg-${var.project_name}-${var.service_name}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${data.aws_vpc.ecsClusterVpc.id}"
}


resource "aws_lb_listener" "ecsAlb" {
  load_balancer_arn = "${aws_lb.ecsAlb.arn}"
  port              = "80"
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2015-05"
  #certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    target_group_arn = "${aws_lb_target_group.ecsAlb.arn}"
    type             = "forward"
  }
}

data "aws_ecr_repository" "service" {
  name = "${var.project_name}"
}

#data "aws_ecs_container_definition" "perSevice" {
# task_definition = "${aws_ecs_task_definition.perService.id}"
# container_name  = "mongodb"
#}

data "template_file" "containerDefinition" {
  template = <<EOF
[
  {
    "cpu": 128,
    "essential": true,
    "portMappings": [
       { "containerPort": 443, "hostPort": 0 }
    ],
    "image": "$${ecr_repository}:latest",
    "memory": 128,
    "memoryReservation": 64,
    "name": "$${name}"
  }
]
EOF

  vars {
    ecr_repository = "973800055156.dkr.ecr.eu-west-1.amazonaws.com/pocsch" #"${data.aws_ecr_repository.service.repository_url}"
    name = "ct-${var.project_name}-${var.service_name}"
  }
}


resource "aws_ecs_task_definition" "perService" {
  family = "task-${var.project_name}-${var.service_name}"
  container_definitions = "${data.template_file.containerDefinition.rendered}"
}

data "aws_ecs_cluster" "ecs_cluster" {
  cluster_name = "ecs-cluster-${var.project_name}"
}

resource "aws_ecs_service" "perService" {
  name          = "srv-${var.project_name}-${var.service_name}"
  cluster       = "${data.aws_ecs_cluster.ecs_cluster.id}"
  desired_count = 1

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.perService.family}:${max("${aws_ecs_task_definition.perService.revision}", "${aws_ecs_task_definition.perService.revision}")}"

  load_balancer {
    target_group_arn  = "${aws_lb_target_group.ecsAlb.arn}"
    container_name = "ct-${var.project_name}-${var.service_name}"
    container_port = 443
  }
}


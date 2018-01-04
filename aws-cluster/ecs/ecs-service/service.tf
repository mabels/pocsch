variable "project_name" {}
variable "service_name" {}

variable "min_size" {
  default = 1
}
variable "max_size" {
  default = 1
}
#variable "services" {}
variable "instance_type" {
  type = "string"
  default = "t2.micro"
}

#variable "asg_regions" {
#  type = "list"
#}

resource "aws_vpc" "ecsClusterVpc" {
  cidr_block       = "10.0.0.0/16"
  tags { Name = "ecs-vpc-${var.project_name}-${var.service_name}" }
}

#resource "aws_eip" "ecsEip" {
#  vpc      = true
#  # name     = "ecsEip-${var.project_name}-${var.service_name}"
#  depends_on = ["aws_internet_gateway.ecsInternetGateway"]
#  #tags {
#  #  Name        = "ecsEip-${var.name}"
#  #}
#}
#
#
#resource "aws_nat_gateway" "ecsNatGateway" {
#  # name   = "ngy-${var.name}"
#  # vpc_id = "${aws_vpc.ecsClusterVpc.id}"
#  subnet_id = "${aws_subnet.ecsCLusterSubNet.id}"
#  allocation_id = "${aws_eip.ecsEip.id}"
#  tags {
#    Name        = "ngy-${var.name}"
#    Environment = "${var.name}"
#  }
#  depends_on = ["aws_eip.ecsEip"]
#}

resource "aws_internet_gateway" "ecsInternetGateway" {
    vpc_id = "${aws_vpc.ecsClusterVpc.id}"
    tags {
        Name        = "ecs-igy-${var.project_name}-${var.service_name}"
        Environment = "${var.project_name}-${var.service_name}"
    }
}

data "aws_availability_zones" "available" {
}

resource "aws_subnet" "ecsCLusterSubNet" {
  count = "${length(data.aws_availability_zones.available.names)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block       = "10.0.${count.index}.0/24"
  vpc_id = "${aws_vpc.ecsClusterVpc.id}"
  tags { Name = "ecs-sn-${var.project_name}-${var.service_name}-${count.index}" }
  depends_on = ["aws_vpc.ecsClusterVpc"]
}

data "aws_subnet_ids" "byVpc" {
  vpc_id = "${aws_vpc.ecsClusterVpc.id}"
  depends_on = ["aws_subnet.ecsCLusterSubNet"]
}

resource "aws_route_table" "ecsDefaultGw" {
  vpc_id = "${aws_vpc.ecsClusterVpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.ecsInternetGateway.id}"
  }

  tags {
    Name = "rt-dt-${aws_vpc.ecsClusterVpc.id}"
  }
}

resource "aws_main_route_table_association" "ecsDefaultGw" {
  vpc_id = "${aws_vpc.ecsClusterVpc.id}"
  route_table_id = "${aws_route_table.ecsDefaultGw.id}"
}

resource "aws_route_table_association" "ecsDefaultGw" {
  count = "${length(data.aws_availability_zones.available.names)}"
  subnet_id = "${aws_subnet.ecsCLusterSubNet.*.id[count.index]}"
  route_table_id = "${aws_route_table.ecsDefaultGw.id}"
}


data "aws_ami" "EcsAmi" {
  filter {
    name   = "state"
    values = ["available"]
  }
  name_regex = "^ecs_.*"
  most_recent      = true
}



resource "aws_iam_role" "ecsAsgRole" {
  name = "ecsAsgRole-${var.project_name}-${var.service_name}"
  assume_role_policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  #tags {
  #  Name        = "ecsAsgRole-${var.name}"
  #}
}

resource "aws_iam_role_policy" "ecsAsgRole" {
  name = "ecsAsgRole-${var.project_name}-${var.service_name}"
  role = "${aws_iam_role.ecsAsgRole.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:CreateCluster",
        "ecs:DeregisterContainerInstance",
        "ecs:DiscoverPollEndpoint",
        "ecs:Poll",
        "ecs:RegisterContainerInstance",
        "ecs:StartTelemetrySession",
        "ecs:Submit*",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecs:StartTask"
      ],
      "Resource": "*"
    }
  ]
}
EOF
  #tags {
  #  Name        = "ecsAsgRole-${var.name}"
  #}
}

resource "aws_iam_instance_profile" "ecsAsgRole" {
  name = "ecsAsgRoleProfile-${var.project_name}-${var.service_name}"
  role = "${aws_iam_role.ecsAsgRole.name}"
  #tags {
  #  Name        = "ecsAsgRole-${var.name}"
  #}
}

resource "aws_security_group" "ec2ssh" {
  name       = "node-sg-ssh"
  vpc_id     = "${aws_vpc.ecsClusterVpc.id}"
  tags {
    Name        = "ec2-sy-ssh"
  }
}

resource "aws_security_group_rule" "ec2ssh" {
  type            = "ingress"
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ec2ssh.id}"
}

resource "aws_security_group_rule" "outboundAll" {
  type            = "egress"
  from_port       = 0
  to_port         = 65535
  protocol        = "all"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ec2ssh.id}"
}


resource "aws_launch_configuration" "ecsService" {
  name_prefix          = "ecs-cluster-${var.project_name}-${var.service_name}-"
  instance_type        = "${var.instance_type}"
  image_id             = "${data.aws_ami.EcsAmi.image_id}"
  key_name             = "gpg-meno" # DEBUG
  associate_public_ip_address = true
  iam_instance_profile = "${aws_iam_instance_profile.ecsAsgRole.name}"
  user_data            = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${aws_ecs_cluster.ecsService.name} >> /etc/ecs/ecs.config
EOF
#  vpc_classic_link_id  = "${aws_vpc.ecsClusterVpc.id}"
#  vpc_classic_link_security_groups = ["${aws_security_group.ecsSecurity.id}"]
  security_groups      = ["${aws_security_group.ec2ssh.id}"]
  lifecycle {
    create_before_destroy = true
  }
  #tags {
  #  Name        = "ecsService-${var.name}"
  #}
  depends_on = ["aws_ecs_cluster.ecsService"]
}




resource "aws_autoscaling_group" "ecsServiceAutoScaling" {
  # availability_zones        = "${var.asg_regions}"
  name                 = "ecs-auto-scaling-cluster-${var.project_name}-${var.service_name}"
  launch_configuration = "${aws_launch_configuration.ecsService.name}"
  vpc_zone_identifier  = ["${aws_subnet.ecsCLusterSubNet.*.id}"]
  min_size             = "${var.min_size}"
  max_size             = "${var.max_size}"
  depends_on = ["aws_launch_configuration.ecsService"]
  lifecycle {
    create_before_destroy = true
  }
  #tags {
  #  Name        = "ecsAs-${var.name}"
  #}

}

resource "aws_ecs_cluster" "ecsService" {
  name = "ecs-cluster-${var.project_name}-${var.service_name}"
}

data "aws_iam_policy_document" "alb_logs" {
  statement {
    effect = "Allow"
    principals = {
      type =  "AWS"
      identifiers = [ "arn:aws:iam::156460612806:root" ]
    },
    actions = [ "s3:PutObject" ]
    resources = [ "arn:aws:s3:::ecs-alb-${lower(var.project_name)}-${lower(var.service_name)}-logs/*" ]
  }
}

resource "aws_s3_bucket" "alb_logs" {
  bucket = "ecs-alb-${lower(var.project_name)}-${lower(var.service_name)}-logs"
  acl    = "private"
  policy = "${data.aws_iam_policy_document.alb_logs.json}"
  tags {
    Name        = "ecs-alb-${var.project_name}-${var.service_name}-logs"
    Environment = "${var.project_name}-${var.service_name}"
  }
}

resource "aws_security_group" "ecsSecurityAlb" {
  name       = "node-sg-${var.project_name}-${var.service_name}"
  vpc_id     = "${aws_vpc.ecsClusterVpc.id}"
  tags {
    Name        = "ecs-sy-alb-${var.project_name}-${var.service_name}"
  }
}

resource "aws_security_group_rule" "ecsSecurityAlbHttp" {
  type            = "ingress"
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ecsSecurityAlb.id}"
}

resource "aws_security_group_rule" "ecsSecurityAlbOutbound" {
  type            = "egress"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  cidr_blocks     = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.ecsSecurityAlb.id}"
}

#data "aws_s3_bucket" "alb_logs" {
#  bucket = "ecs-alb-stage-logs"
#}

resource "aws_lb" "ecsAlb" {
  name            = "ecs-alb-${var.project_name}-${var.service_name}"
  internal        = false
  security_groups = ["${aws_security_group.ecsSecurityAlb.id}"]
  subnets         = ["${data.aws_subnet_ids.byVpc.ids}"]

  enable_deletion_protection = false

  access_logs {
    bucket = "${aws_s3_bucket.alb_logs.bucket}"
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
  vpc_id   = "${aws_vpc.ecsClusterVpc.id}"
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

#data "aws_ecs_cluster" "ecs_cluster" {
# cluster_name = "ecs-cluster-${var.project_name}"
#}

resource "aws_ecs_service" "perService" {
  name          = "srv-${var.project_name}-${var.service_name}"
  cluster       = "${aws_ecs_cluster.ecsService.id}"
  desired_count = 1

  # Track the latest ACTIVE revision
  task_definition = "${aws_ecs_task_definition.perService.family}:${max("${aws_ecs_task_definition.perService.revision}", "${aws_ecs_task_definition.perService.revision}")}"

  load_balancer {
    target_group_arn  = "${aws_lb_target_group.ecsAlb.arn}"
    container_name = "ct-${var.project_name}-${var.service_name}"
    container_port = 443
  }
  depends_on = ["aws_lb_listener.ecsAlb"]
}

resource "aws_security_group_rule" "lbaccess" {
  type            = "ingress"
  from_port       = 0
  to_port         = 65535
  protocol        = "tcp"
  source_security_group_id = "${aws_security_group.ecsSecurityAlb.id}"
  security_group_id = "${aws_security_group.ec2ssh.id}"
}

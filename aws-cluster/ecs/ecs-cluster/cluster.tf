variable "name" {}
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
  tags { Name = "ecs-vpc-${var.name}" }
}

#resource "aws_eip" "ecsEip" {
#  vpc      = true
#  # name     = "ecsEip-${var.name}"
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
        Name        = "ecs-igy-${var.name}"
        Environment = "${var.name}"
    }
}

data "aws_availability_zones" "available" {
}

resource "aws_subnet" "ecsCLusterSubNet" {
  count = "${length(data.aws_availability_zones.available.names)}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block       = "10.0.${count.index}.0/24"
  vpc_id = "${aws_vpc.ecsClusterVpc.id}"
  tags { Name = "ecs-sn-${var.name}-${count.index}" }
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
  name = "ecsAsgRole-${var.name}"
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
  name = "ecsAsgRole-${var.name}"
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
  name = "ecsAsgRoleProfile-${var.name}"
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
  name_prefix          = "ecs-cluster-${var.name}-"
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
  name                 = "ecs-auto-scaling-cluster-${var.name}"
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
  name = "ecs-cluster-${var.name}"
}

data "aws_iam_policy_document" "alb_logs" {
  statement {
    effect = "Allow"
    principals = {
      type =  "AWS"
      identifiers = [ "arn:aws:iam::156460612806:root" ]
    },
    actions = [ "s3:PutObject" ]
    resources = [ "arn:aws:s3:::ecs-alb-${var.name}-logs/*" ]
  }
}

resource "aws_s3_bucket" "alb_logs" {
  bucket = "ecs-alb-${var.name}-logs"
  acl    = "private"
  policy = "${data.aws_iam_policy_document.alb_logs.json}"
  tags {
    Name        = "ecs-alb-${var.name}-logs"
    Environment = "${var.name}"
  }
}


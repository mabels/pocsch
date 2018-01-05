variable "name" {}
variable "description" {}
variable "users" {
  type = "map"
}

resource "aws_ecr_repository" "pocsch_ecr_repros" {
  name = "${var.name}"
}

resource "aws_codecommit_repository" "git_repos" {
  repository_name = "${var.name}"
  description     = "${var.description}"
}

data "aws_iam_policy_document" "GitReproPolicyDocument" {
  statement {
    actions = [
                "codecommit:BatchGet*",
                "codecommit:Get*",
                "codecommit:List*",
                "codecommit:Create*",
                "codecommit:DeleteBranch",
                "codecommit:Describe*",
                "codecommit:Put*",
                "codecommit:Post*",
                "codecommit:Merge*",
                "codecommit:Test*",
                "codecommit:Update*",
                "codecommit:GitPull",
                "codecommit:GitPush"
    ]
    resources = [
      "${aws_codecommit_repository.git_repos.*.arn}"
    ]
  }
}

resource "aws_iam_group" "GitReproGroups" {
  name = "git-${var.name}"
  path = "/"
}

resource "aws_iam_group_policy" "GitReproGroupsPolicy" {
  name  = "git-${var.name}"
  group = "git-${var.name}"
  policy = "${data.aws_iam_policy_document.GitReproPolicyDocument.json}"
}

resource "aws_iam_user" "GitReproUsers" {
  count = "${length(var.users)}"
  name = "${lookup(var.users[count.index], "name")}"
  depends_on = ["aws_iam_group.GitReproGroups"]
}

resource "aws_iam_user_ssh_key" "GitReproUsersSsh" {
  count = "${length(var.users)}"
  username   = "${lookup(var.users[count.index], "name")}"
  encoding   = "SSH"
  public_key = "${lookup(var.users[count.index], "ssh")}"
  depends_on = ["aws_iam_user.GitReproUsers"]
}

data "template_file" "groups" {
  count    = "${length(var.users)}"
  template = "$${name}"
  vars {
    name = "${lookup(var.users[count.index], "name")}"
  }
}

resource "aws_iam_group_membership" "GitReproAddGroup" {
  name = "GitReproGroupMembership-${var.name}"

  users = [ "${data.template_file.groups.*.rendered}" ]


  group = "git-${var.name}"
  depends_on = ["aws_iam_user.GitReproUsers", "aws_iam_group.GitReproGroups"]
}

#
#resource "aws_lambda_permission" "code_build_trigger_perm_invoke" {
#  count = "${length(var.git_repros)}"
#  statement_id   = "AllowCodeBuildTriggerPerm"
#  action         = "lambda:InvokeFunction"
#  function_name  = "${aws_lambda_function.code_build_trigger.function_name}"
#  principal      = "codecommit.amazonaws.com"
#  #source_account = "${aws_codecommit_repository.git_repos.*.repository_id[count.index]}"
#  source_arn     = "${aws_codecommit_repository.git_repos.*.arn[count.index]}"
#  #source_account = "${lookup(aws_codecommit_repository.git_repos[count.index], "repository_id")}"
#  #source_arn     = "${lookup(aws_codecommit_repository.git_repos[count.index], "arn")}"
#}

#resource "aws_lambda_function" "code_build_trigger" {
#  filename         = "code_build_trigger.zip"
#  function_name    = "code_build_trigger"
#  role             = "${aws_iam_role.code_build_trigger_role.arn}"
#  handler          = "code_build_trigger.handler"
#  source_code_hash = "${base64sha256(file("code_build_trigger.zip"))}"
#  runtime          = "nodejs6.10"
#}
#
#resource "aws_codecommit_trigger" "git_repos" {
#  repository_name = "${lookup(var.git_repros[count.index], "name")}"
#
#  trigger {
#    name            = "code_build_trigger"
#    events          = ["all"]
#    destination_arn = "${aws_lambda_function.code_build_trigger.arn}"
#  }
#
#  depends_on      = ["aws_codecommit_repository.git_repos"]
#}



resource "aws_iam_role" "code_build_trigger_role" {
   name = "codebuilder-for-${var.name}"
    #{
    #  "Action": "sts:AssumeRole",
    #  "Principal": {
    #    "Service": "lambda.amazonaws.com"
    #  },
    #  "Effect": "Allow"
    #},
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "code_build_trigger_role_logs" {
    role       = "${aws_iam_role.code_build_trigger_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_iam_role_policy_attachment" "code_build_trigger_role_gitaccess_attach" {
    role       = "${aws_iam_role.code_build_trigger_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
}

resource "aws_iam_role_policy_attachment" "code_build_trigger_role_code_build" {
    role       = "${aws_iam_role.code_build_trigger_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "code_build_trigger_role_ecr" {
    role       = "${aws_iam_role.code_build_trigger_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/AWSCodeBuildAdminAccess"
}

resource "aws_s3_bucket" "code_build" {
  bucket = "ecs-cb-${var.name}"
  acl    = "private"
  #policy = "${data.aws_iam_policy_document.alb_logs.json}"
  tags {
    Name        = "ecs-cb-${lower(var.name)}"
    Environment = "ecs-cb-${var.name}"
  }
}

resource "aws_codebuild_project" "code_build" {
   name = "codebuild-project-${var.name}"
   description  = "codebuild-project-${var.name}"
  build_timeout      = "5"
  service_role = "${aws_iam_role.code_build_trigger_role.*.arn[count.index]}"
 
  artifacts {
    type = "S3"
    location = "ecs-cb-${lower(var.name)}"
    name = "imagedefinitions.json"
    path = "/"
  }
   environment {
     compute_type = "BUILD_GENERAL1_SMALL"
     image        = "aws/codebuild/docker:17.09.0"
     privileged_mode = true
     type         = "LINUX_CONTAINER"
   }
   source {
     type     = "CODECOMMIT"
     location = "https://git-codecommit.eu-west-1.amazonaws.com/v1/repos/${var.name}"
   }

  #depends_on = ["aws_iam_role_policy_attachment.code_build_trigger_role_code_build"]

 
 }



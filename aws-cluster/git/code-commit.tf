
variable "git_repros" {
  default = [
    {
      name = "pocsch"
      description = "description pocsch-git"
    },
#    {
#      name = "pocsch-0"
#      description = "description pocsch-0-git"
#    }
  ]
}


variable "git_users" {
  type = "map"
  default = {
    "0" = {
      name = "posch-user-1"
      ssh  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIQpC2scaVXEaNuwtq4n6Vtht2WHYxtDFKe44JNFEsZGyQjyL9c2qkmQQGCF+2g3HrIPDTCCCWQ3GUiXGAlQ0/rf6sLqcm4YMXt+hgHU5VeciUIDEySCKdCPC419wFPBw6oKdcN1pLoIdWoF4LRDcjcrKKAlkdNJ/oLnl716piLdchABO9NXGxBpkLsJGK8qw390O1ZqZMe9wEAL9l/A1/49v8LfzELp0/fhSmiXphTVI/zNVIp/QIytXzRg74xcYpBjHk1TQZHuz/HYYsWwccnu7vYaTDX0CCoAyEt599f9u+JQ4oW0qyLO0ie7YcmR6nGEW4DMsPcfdqqo2VyYy4ix3U5RI2JcObfP0snYwPtAdVeeeReXi3c/E7bGLeCcwdFeFBfHSA9PDGxWVlxh/oCJaE7kP7eBhXNjN05FodVdNczKI5T9etfQ9VHILFrvpEREg1+OTiI58RmwjxS5ThloqXvr/nZzhIwTsED0KNW8wE4pjyotDJ8jaW2d7oVIMdWqE2M9Z1sLqDDdhHdVMFxk6Hl2XfqeqO2Jnst7qzbHAN/S3hvSwysixWJEcLDVG+cg1KRwz4qafCU5oHSp8aNNOk4RZozboFjac17nOmfPfnjC/LLayjSkEBZ+eFi+njZRLDN92k3PvHYFEB3USbHYzICsuDcf+L4cslX03g7w== openpgp:0x5F1BE34D"
    }
#    "1" = {
#      name = "posch-user-2"
#      ssh  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDIQpC2scaVXEaNuwtq4n6Vtht2WHYxtDFKe44JNFEsZGyQjyL9c2qkmQQGCF+2g3HrIPDTCCCWQ3GUiXGAlQ0/rf6sLqcm4YMXt+hgHU5VeciUIDEySCKdCPC419wFPBw6oKdcN1pLoIdWoF4LRDcjcrKKAlkdNJ/oLnl716piLdchABO9NXGxBpkLsJGK8qw390O1ZqZMe9wEAL9l/A1/49v8LfzELp0/fhSmiXphTVI/zNVIp/QIytXzRg74xcYpBjHk1TQZHuz/HYYsWwccnu7vYaTDX0CCoAyEt599f9u+JQ4oW0qyLO0ie7YcmR6nGEW4DMsPcfdqqo2VyYy4ix3U5RI2JcObfP0snYwPtAdVeeeReXi3c/E7bGLeCcwdFeFBfHSA9PDGxWVlxh/oCJaE7kP7eBhXNjN05FodVdNczKI5T9etfQ9VHILFrvpEREg1+OTiI58RmwjxS5ThloqXvr/nZzhIwTsED0KNW8wE4pjyotDJ8jaW2d7oVIMdWqE2M9Z1sLqDDdhHdVMFxk6Hl2XfqeqO2Jnst7qzbHAN/S3hvSwysixWJEcLDVG+cg1KRwz4qafCU5oHSp8aNNOk4RZozboFjac17nOmfPfnjC/LLayjSkEBZ+eFi+njZRLDN92k3PvHYFEB3USbHYzICsuDcf+L4cslX03g7w== openpgp:0x5F1BE34D"
#    }
  }
}

resource "aws_codecommit_repository" "git_repos" {
  count = "${length(var.git_repros)}"
  repository_name = "${lookup(var.git_repros[count.index], "name")}"
  description     = "${lookup(var.git_repros[count.index], "description")}"
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
      # "arn:aws:codecommit:eu-west-1:973800055156:pocsch",
    ]
  }
}

resource "aws_iam_group" "GitReproGroups" {
  count = "${length(var.git_repros)}"
  name = "git-${lookup(var.git_repros[count.index], "name")}"
  path = "/"
}

resource "aws_iam_group_policy" "GitReproGroupsPolicy" {
  count = "${length(var.git_repros)}"
  name  = "git-${lookup(var.git_repros[count.index], "name")}"
  group = "git-${lookup(var.git_repros[count.index], "name")}"
  policy = "${data.aws_iam_policy_document.GitReproPolicyDocument.json}"
}

resource "aws_iam_user" "GitReproUsers" {
  count = "${length(var.git_users)}"
  name = "${lookup(var.git_users[count.index], "name")}"
}

resource "aws_iam_user_ssh_key" "GitReproUsersSsh" {
  count = "${length(var.git_users)}"
  username   = "${lookup(var.git_users[count.index], "name")}"
  encoding   = "SSH"
  public_key = "${lookup(var.git_users[count.index], "ssh")}"
  depends_on = ["aws_iam_user.GitReproUsers"]
}

data "template_file" "groups" {
  count    = "${length(var.git_users)}"
  template = "$${name}"
  vars {
    name = "${lookup(var.git_users[count.index], "name")}"
  }
}

resource "aws_iam_group_membership" "GitReproAddGroup" {
  count = "${length(var.git_repros)}"
  name = "GitReproGroupMembership-${lookup(var.git_repros[count.index], "name")}"

  users = [ "${data.template_file.groups.*.rendered}" ]


  group = "git-${lookup(var.git_repros[count.index], "name")}"
  depends_on = ["aws_iam_user.GitReproUsers", "aws_iam_group.GitReproGroups"]
}

resource "aws_lambda_permission" "code_build_trigger_perm_invoke" {
  count = "${length(var.git_repros)}"
  statement_id   = "AllowCodeBuildTriggerPerm"
  action         = "lambda:InvokeFunction"
  function_name  = "${aws_lambda_function.code_build_trigger.function_name}"
  principal      = "codecommit.amazonaws.com"
  #source_account = "${aws_codecommit_repository.git_repos.*.repository_id[count.index]}"
  source_arn     = "${aws_codecommit_repository.git_repos.*.arn[count.index]}"
  #source_account = "${lookup(aws_codecommit_repository.git_repos[count.index], "repository_id")}"
  #source_arn     = "${lookup(aws_codecommit_repository.git_repos[count.index], "arn")}"
}

resource "aws_lambda_function" "code_build_trigger" {
  filename         = "code_build_trigger.zip"
  function_name    = "code_build_trigger"
  role             = "${aws_iam_role.code_build_trigger_role.arn}"
  handler          = "code_build_trigger.handler"
  source_code_hash = "${base64sha256(file("code_build_trigger.zip"))}"
  runtime          = "nodejs6.10"
}

resource "aws_codecommit_trigger" "git_repos" {
  depends_on      = ["aws_codecommit_repository.git_repos"]
  repository_name = "${lookup(var.git_repros[count.index], "name")}"

  trigger {
    name            = "code_build_trigger"
    events          = ["all"]
    destination_arn = "${aws_lambda_function.code_build_trigger.arn}"
  }
}



resource "aws_iam_role" "code_build_trigger_role" {
  name = "code_build_trigger_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "code_build_trigger_role_exec" {
  name = "code_build_trigger_role_exec"
  role = "${aws_iam_role.code_build_trigger_role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "code_build_trigger_role_gitaccess_attach" {
    role       = "${aws_iam_role.code_build_trigger_role.name}"
    policy_arn = "arn:aws:iam::aws:policy/AWSCodeCommitFullAccess"
}


resource "aws_iam_role" "codePipeline" {
  name = "cp-${var.name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "cpp-${var.name}"
  role = "${aws_iam_role.codePipeline.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "${aws_s3_bucket.code_build.arn}",
        "${aws_s3_bucket.code_build.arn}/*"
      ]
    },
    {
      "Effect":"Allow",
      "Action": [
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
       ],
      "Resource": [
        "${aws_codecommit_repository.git_repos.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_codepipeline" "git_repros" {
  name = "cp-${var.name}"
  role_arn = "${aws_iam_role.codePipeline.arn}"

  artifact_store {
    location = "${aws_s3_bucket.code_build.bucket}"
    type     = "S3"
  }

  stage {
    name = "CodeCommit-${var.name}"

    action {
      name             = "Source-${var.name}"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["${var.name}"]

      configuration {
        RepositoryName = "pocsch"
        BranchName     = "master"
      }
    }
  }

  stage {
    name = "CodeBuild-${var.name}"

    action {
      name            = "Build-${var.name}"
      category        = "Build"
      owner           = "AWS"
      provider        = "CodeBuild"
      input_artifacts = ["${var.name}"]
      version         = "1"

      configuration {
        ProjectName = "${var.name}"
      }

    }
  }

}

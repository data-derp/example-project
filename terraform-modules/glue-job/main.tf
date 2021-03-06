resource "aws_glue_job" "this" {
  name     = "${var.project-name}-${var.module-name}-${var.submodule-name}"
  role_arn = aws_iam_role.this.arn

  number_of_workers = 2
  worker_type = "Standard"
  glue_version = "2.0"

  command {
    script_location = "s3://${data.aws_s3_bucket.this.bucket}/${var.script-path}"
  }

  default_arguments = merge({
    "--job-language" = "python"
    "--continuous-log-logGroup"          = aws_cloudwatch_log_group.this.name
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
    "--enable-metrics"                   = ""
    "--TempDir"                          = "s3://${data.aws_s3_bucket.this.bucket}/${var.submodule-name}/temp/"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = "s3://${var.project-name}-${var.module-name}-spark-logs/"
  },var.additional-params)
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.project-name}-${var.module-name}-${var.submodule-name}/glue"
  retention_in_days = 14
}

data "aws_s3_bucket" "this" {
  bucket = "${var.project-name}-${var.module-name}"
}

resource "aws_iam_role" "this" {
  name = "${var.project-name}-${var.module-name}-${var.submodule-name}-glue"
  permissions_boundary = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.project-name}-${var.module-name}/${var.project-name}-${var.module-name}-delegated-boundary"
  force_detach_policies = true
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "glue.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "glue-service-role" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

// TODO: This should be further locked down
resource "aws_iam_role_policy_attachment" "s3-full-access" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

// TODO: This should be further locked down
data "aws_iam_policy_document" "kms" {
  statement {
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:*:/aws-glue/*",
      aws_cloudwatch_log_group.this.arn
    ]
  }
}

resource "aws_iam_policy" "kms" {
  policy = data.aws_iam_policy_document.kms.json
}

resource "aws_iam_role_policy_attachment" "kms" {
  role       = aws_iam_role.this.id
  policy_arn = aws_iam_policy.kms.arn
}

data "aws_caller_identity" "current" {}
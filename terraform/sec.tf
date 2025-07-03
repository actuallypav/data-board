resource "aws_iam_role" "metabase_s3_output_role" {
  name = "metabase-s3-output-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "metabase_s3_output_policy" {
  name        = "metabase-s3-output-policy"
  description = "Allow Metabase to write exports to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          "${aws_s3_bucket.metabase_exports.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.metabase_exports.arn
        ]
      }
    ]
  })

}

resource "aws_iam_role_policy_attachment" "metabase_s3_output_attach" {
  role       = aws_iam_role.metabase_s3_output_role.name
  policy_arn = aws_iam_policy.metabase_s3_output_policy.arn
}

resource "aws_iam_instance_profile" "metabase_s3_output_profile" {
  name = "metabase-s3-output-profile"
  role = aws_iam_role.metabase_s3_output_role.name
}


resource "aws_iam_role" "itr_lambda_exec_role" {
  name = "itr_lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "lambda_rds_policy" {
  name = "lambda_rds_policy"
  role = aws_iam_role.itr_lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Effect   = "Allow",
        Resource = "*"
      },
      {
        Action = [
          "rds:*",
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_lambda_permission" "allow_iot" {
  statement_id  = "AllowExecutionFromIoT"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.iot_to_rds.function_name
  principal     = "iot.amazonaws.com"
}
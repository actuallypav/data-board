resource "aws_lambda_function" "iot_to_rds" {
  filename         = "../src/lambda/iot_to_rds.zip"
  function_name    = "iot_to_rds_lambda"
  role             = aws_iam_role.itr_lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 10
  source_code_hash = filebase64sha256("../src/lambda/iot_to_rds.zip")

  environment {
    variables = {
      DB_HOST     = aws_db_instance.iot_rds_instance.address
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
      DB_NAME     = "visualization_db"
    }
  }

  vpc_config {
    subnet_ids = [
      aws_subnet.private_db_a.id,
      aws_subnet.private_db_b.id
    ]
    security_group_ids = [
      aws_security_group.lambda_sg.id
    ]
  }

  depends_on = [aws_db_instance.iot_rds_instance]
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

resource "aws_iot_topic_rule" "temp_to_lambda" {
  name        = "temp_to_lambda"
  enabled     = true
  sql         = "SELECT * FROM 'Temp'"
  sql_version = "2016-03-23"

  lambda {
    function_arn = aws_lambda_function.iot_to_rds.arn
  }

  depends_on = [
    aws_lambda_permission.allow_iot
  ]
}

resource "aws_lambda_permission" "allow_iot" {
  statement_id  = "AllowExecutionFromIoT"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.iot_to_rds.function_name
  principal     = "iot.amazonaws.com"
}
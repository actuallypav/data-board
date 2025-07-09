resource "aws_lambda_function" "iot_to_rds" {
  filename         = "../src/lambda/iot_to_rds.zip"
  function_name    = "iot_to_rds_lambda"
  role             = aws_iam_role.itr_lambda_exec_role.arn
  handler          = "main.lambda_handler"
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

  depends_on = [null_resource.package_lambda, aws_db_instance.iot_rds_instance]
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

resource "null_resource" "package_lambda" {
  provisioner "local-exec" {
    command = <<EOT
      cd "${path.module}/../src/lambda/lambda_build"
      pip install -r requirements.txt -t .
      zip -r ../iot_to_rds.zip . -x "__pycache__/*"
    EOT
  }

  triggers = {
    always_run = timestamp()
  }
}
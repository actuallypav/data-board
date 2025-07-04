resource "aws_lambda_function" "bootstrap_db" {
  filename         = "../src/bootstrap_lambda/bootstrap_lambda.zip"
  function_name    = "bootstrap_db_lambda"
  role             = aws_iam_role.itr_lambda_exec_role.arn
  handler          = "bootstrap_lambda.lambda_handler"
  runtime          = "python3.11"
  timeout          = 10
  source_code_hash = filebase64sha256("../src/bootstrap_lambda/bootstrap_lambda.zip")

  environment {
    variables = {
      DB_HOST     = aws_db_instance.iot_rds_instance.address
      DB_USER     = var.db_username
      DB_PASSWORD = var.db_password
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_db_a.id, aws_subnet.private_db_b.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  depends_on = [aws_db_instance.iot_rds_instance]
}
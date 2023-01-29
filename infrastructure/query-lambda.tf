data "archive_file" "query_lambda" {
  type        = "zip"
  source_file = "../dist/query-lambda.js"
  output_path = "../dist/query-lamdba.zip"
}

resource "aws_lambda_function" "query_lambda_function" {
  filename         = data.archive_file.query_lambda.output_path
  source_code_hash = filebase64sha256(data.archive_file.query_lambda.output_path)
  function_name    = "${terraform.workspace}-dynamodb-full-text-search-query"
  role             = aws_iam_role.iam_role.arn
  handler          = "query-lambda.handler"
  runtime          = "nodejs18.x"
  memory_size      = 1769 # = 1 vCPU as per https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html
  timeout          = 60

  vpc_config {
    subnet_ids         = [aws_subnet.subnet_public.id]
    security_group_ids = [aws_default_security_group.default_security_group.id]
  }

  file_system_config {
    arn              = aws_efs_access_point.lambda_access_point.arn
    local_mount_path = "/mnt/efs"
  }
  depends_on = [aws_efs_mount_target.mount_target_public]

  environment {
    variables = {
      MOUNT_PATH   = "/mnt/efs",
      DYNAMO_TABLE = aws_dynamodb_table.dynamo_table.name,
    }
  }
}

resource "aws_lambda_function_url" "query_lambda_function_public_url" {
  function_name      = aws_lambda_function.query_lambda_function.function_name
  authorization_type = "NONE"
}

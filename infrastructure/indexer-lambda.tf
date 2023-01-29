data "archive_file" "indexer_lambda" {
  type        = "zip"
  source_file = "../dist/indexer-lambda.js"
  output_path = "../dist/indexer-lamdba.zip"
}

data "aws_iam_policy_document" "assume_lambda_policy" {
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      # for stream
      "dynamodb:GetRecords",
      "dynamodb:GetShardIterator",
      "dynamodb:DescribeStream",
      "dynamodb:ListStreams",
      # for internal usage by own code
      "dynamodb:Scan",
    ]
    resources = [
      "arn:aws:dynamodb:*:*:table/${aws_dynamodb_table.dynamo_table.name}*"
    ]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "dynamodb-full-text-search-lambda"
  policy = data.aws_iam_policy_document.lambda_policy.json
}


resource "aws_iam_role" "iam_role" {
  assume_role_policy = data.aws_iam_policy_document.assume_lambda_policy.json
  name               = "dynamodb-full-text-search-lambda"
}

resource "aws_iam_role_policy_attachment" "iam_role_policy_attachment_lambda_basic_execution" {
  role       = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "index_lambda_function" {
  filename                       = data.archive_file.indexer_lambda.output_path
  source_code_hash               = filebase64sha256(data.archive_file.indexer_lambda.output_path)
  function_name                  = "${terraform.workspace}-dynamodb-full-text-search-index"
  role                           = aws_iam_role.iam_role.arn
  handler                        = "indexer-lambda.handler"
  runtime                        = "nodejs18.x"
  memory_size                    = 1769 # = 1 vCPU as per https://docs.aws.amazon.com/lambda/latest/dg/gettingstarted-limits.html
  reserved_concurrent_executions = 1    # only 1 lambda should be indexing the full-text db at a time
  timeout                        = 60

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

resource "aws_lambda_event_source_mapping" "dynamodb_streams_to_indexer_lambda" {
  event_source_arn       = aws_dynamodb_table.dynamo_table.stream_arn
  function_name          = aws_lambda_function.index_lambda_function.arn
  parallelization_factor = 1 # only 1 lambda should be indexing the full-text db at a time
  starting_position      = "LATEST"
}

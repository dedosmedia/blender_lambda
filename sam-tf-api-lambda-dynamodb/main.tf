# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

terraform {
  required_version = "~> 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.22.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.1"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 2.12"
    }
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "this" {}

data "aws_ecr_authorization_token" "token" {}

provider "aws" {
  region = "us-east-1"
}

provider "docker" {
  registry_auth {
    address  = format("%v.dkr.ecr.%v.amazonaws.com", data.aws_caller_identity.this.account_id, data.aws_region.current.name)
    username = data.aws_ecr_authorization_token.token.user_name
    password = data.aws_ecr_authorization_token.token.password
  }
}

module "docker_image" {
  source = "terraform-aws-modules/lambda/aws//modules/docker-build"

  create_ecr_repo = true
  ecr_repo        = local.name
  ecr_repo_lifecycle_policy = jsonencode({
    "rules" : [
      {
        "rulePriority" : 1,
        "description" : "Keep only the last 2 images",
        "selection" : {
          "tagStatus" : "any",
          "countType" : "imageCountMoreThan",
          "countNumber" : 2
        },
        "action" : {
          "type" : "expire"
        }
      }
    ]
  })
  image_tag   = local.image_tag
  source_path = "/src" #abspath(path.module) #format("%v/%v",abspath(path.module) + "src")
  build_args = {

  }

}


module "aws_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 2.7"

  function_name = local.name
  environment_variables = {
    "NODE_ENV"            = "production",
    "DYNAMODB_TABLE_NAME" = "${aws_dynamodb_table.book-reviews-ddb-table.id}"
  }
  create_package = false
  lambda_role    = aws_iam_role.iam_for_lambda.arn

  ##################
  # Container Image
  ##################
  image_uri     = module.docker_image.image_uri
  package_type  = "Image"
  architectures = ["x86_64"]

}


/*
# Lambda function desde una imagen de contenedor
resource "aws_lambda_function" "python-lambda-function" {
  function_name = "python-lambda-function"
  description   = "lambda function from terraform"
  image_uri     = "aws_account_id.dkr.ecr.region.amazonaws.com/python-lambda-function:latest"
                # "${data.aws_ecr_repository.my_image.repository_url}:latest"
  memory_size   = 512
  # EphemeralStorage
  timeout       = 300
  package_type  = "Image"
  architectures = ["x86_64"]
  role          = aws_iam_role.lambda-role.arn
  source_code_hash = var.commit_hash  << New line
}
*/

resource "null_resource" "sam_metadata_aws_lambda_function_publish_book_review" {
  triggers = {
    resource_name     = "aws_lambda_function.${local.name}"
    resource_type     = "IMAGE_LAMBDA_FUNCTION"
    docker_context    = abspath(path.module)
    docker_file       = "Dockerfile"
    docker_build_args = jsonencode({}) # TODO: reemplazar con jsonencode(var.buildargs)
    docker_tag        = local.image_tag
  }

}


resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

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

  inline_policy {
    name = "dynamodb_access"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "dynamodb:List*",
            "dynamodb:DescribeReservedCapacity*",
            "dynamodb:DescribeLimits",
            "dynamodb:DescribeTimeToLive"
          ],
          "Resource" : "*",
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "dynamodb:BatchGet*",
            "dynamodb:DescribeStream",
            "dynamodb:DescribeTable",
            "dynamodb:Get*",
            "dynamodb:Query",
            "dynamodb:Scan",
            "dynamodb:BatchWrite*",
            "dynamodb:CreateTable",
            "dynamodb:Delete*",
            "dynamodb:Update*",
            "dynamodb:PutItem"
          ],
          "Resource" : [
            "${aws_dynamodb_table.book-reviews-ddb-table.arn}"
          ],
          "Effect" : "Allow"
        }
      ]
    })
  }

}

resource "aws_dynamodb_table" "book-reviews-ddb-table" {
  name           = "BookReviews"
  billing_mode   = "PROVISIONED"
  read_capacity  = 1
  write_capacity = 1
  hash_key       = "ReviewId"
  range_key      = "BookTitle"

  attribute {
    name = "ReviewId"
    type = "S"
  }

  attribute {
    name = "BookTitle"
    type = "S"
  }

  attribute {
    name = "ReviewScore"
    type = "N"
  }

  global_secondary_index {
    name               = "BookTitleIndex"
    hash_key           = "BookTitle"
    range_key          = "ReviewScore"
    write_capacity     = 1
    read_capacity      = 1
    projection_type    = "INCLUDE"
    non_key_attributes = ["ReviewId"]
  }

  tags = {
    Name = "book-reviews-table"
  }
}


## API Gateway

resource "aws_apigatewayv2_api" "lambda" {
  name          = "book_reviews_service"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name        = "serverless_lambda_stage"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}

resource "aws_apigatewayv2_integration" "publish_book_review_api" {
  api_id = aws_apigatewayv2_api.lambda.id

  integration_uri    = module.aws_lambda.lambda_function_invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

resource "aws_apigatewayv2_route" "publish_book_review_route" {
  api_id = aws_apigatewayv2_api.lambda.id

  route_key = "POST /book-review"
  target    = "integrations/${aws_apigatewayv2_integration.publish_book_review_api.id}"
}

resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.aws_lambda.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*/*"
}

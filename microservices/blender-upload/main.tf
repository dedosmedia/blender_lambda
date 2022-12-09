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
  ecr_repo        = local.function_name
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
  source_path = "src/"
  build_args = {

  }

}


module "aws_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "4.7.1"

  function_name = local.function_name
  environment_variables = {
    "BUCKET_NAME"         = "${aws_s3_bucket.upload.bucket}"
  }
  create_package = false

  number_of_policy_jsons = 1
  attach_policy_jsons = true
  policy_jsons = [
    jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "s3:*"
          ],
          "Resource" : [
            "${aws_s3_bucket.upload.arn}",
            "${aws_s3_bucket.upload.arn}/*"
          ],
          "Effect" : "Allow"
        }
      ]
    })
  ]

  publish = true
  
  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${data.terraform_remote_state.apigateway.outputs.api_execution_arn}/*/*"
    }
  }


  ##################
  # Container Image
  ##################
  image_uri     = module.docker_image.image_uri
  package_type  = "Image"
  architectures = ["x86_64"]

}


data "terraform_remote_state" "apigateway" {
    backend = "local"

    config = {
      path = "../blender-api/terraform.tfstate"
    }
    
}

resource "aws_s3_bucket" "upload" {
  bucket = "${local.function_name}-bucket"

  tags = {
    Name        = local.function_name
    Environment = "Dev"
  }
}


resource "aws_s3_bucket_acl" "private" {
  bucket = aws_s3_bucket.upload.id
  acl    = "private"
}


module "sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "3.5.0"

  name = "${local.function_name}"
}


resource "aws_sqs_queue_policy" "users_unencrypted_policy" {
  queue_url = module.sqs.sqs_queue_id


  policy = jsonencode({
    "Version": "2008-10-17",
    "Id": " policy",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::${data.aws_caller_identity.this.account_id}:root",
          "Service": [
            "s3.amazonaws.com"
          ]
        },
        "Action": [
          "SQS:SendMessage",
          "SQS:ReceiveMessage"
        ],
        "Resource": module.sqs.sqs_queue_arn
      }
    ]
  })
  
  
}

provider "aws" {
  region = "us-east-1"
}

data "aws_route53_zone" "this" {
  name = "dhmoney.co.uk"
}

## Route53 Recorss
module "route53_records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "2.10.1"

  zone_name = data.aws_route53_zone.this.name

  records = [
    {
      name = "api"
      type = "A"
      alias = {
        name =  module.apigateway-v2.apigatewayv2_domain_name_target_domain_name
        zone_id = module.apigateway-v2.apigatewayv2_domain_name_hosted_zone_id
      }
    }
  ]
}

## API Gateway
module "apigateway-v2" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "2.2.1"

  name          = local.function_name
  description   = "Blender API Gateway"
  protocol_type = "HTTP"

  domain_name                 = "api.dhmoney.co.uk"
  domain_name_certificate_arn = "arn:aws:acm:us-east-1:933916524267:certificate/e8b8b23e-ca7a-4257-adc4-618645ca7a52"


  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  # Access logs
  default_stage_access_log_destination_arn = aws_cloudwatch_log_group.api_gw.arn
  default_stage_access_log_format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"

  # Routes and integrations
  integrations = {
    "POST /upload" = {
      lambda_arn             = data.terraform_remote_state.blender_upload.outputs.lambda_arn
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }
  }
}


data "terraform_remote_state" "blender_upload" {
  backend = "local"

  config = {
    path = "../blender-upload/terraform.tfstate"
  }

}

resource "aws_cloudwatch_log_group" "api_gw" {
  name              = "/aws/api_gw/${local.function_name}"
  retention_in_days = 30
}

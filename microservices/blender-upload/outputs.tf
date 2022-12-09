output "lambda_arn" {

  description = "Valor de la función lambda"
  value       = module.aws_lambda.lambda_function_arn
}

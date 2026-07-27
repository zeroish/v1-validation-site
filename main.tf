terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # For testing, use local state. For production, use S3 backend:
  # backend "s3" {
  #   bucket         = "gc-state"
  #   key            = "validation/site/terraform.tfstate"
  #   region         = "us-east-2"
  #   dynamodb_table = "tofu-state-lock"
  # }
}

provider "aws" {
  region = "us-east-2"

  default_tags {
    tags = {
      Environment = "test"
      Project     = "zeroish"
      Purpose     = "v1.0.0-validation"
    }
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"

  default_tags {
    tags = {
      Environment = "test"
      Project     = "zeroish"
      Purpose     = "v1.0.0-validation"
    }
  }
}

variable "domain_name" {
  type        = string
  description = "Domain name for the test site"
  default     = "validation.zeroish.dev"
}

# Create the DNS hosted zone
module "dns_zone" {
  source = "git::https://github.com/zeroish/tofu-modules.git//modules/dns-zone?ref=dns-zone/v1.0.0"
  domain = var.domain_name
  comment = "v1.0.0 validation site"
}

# Create the static site
module "static_site" {
  source    = "git::https://github.com/zeroish/tofu-modules.git//modules/static-site?ref=static-site/v1.0.0"
  providers = {
    aws.us_east_1 = aws.us_east_1
  }
  domain_name   = var.domain_name
  zone_id       = module.dns_zone.zone_id
  force_destroy = true  # Allow cleanup in tests
}

# Simple lambda function code
data "archive_file" "lambda_zip" {
  type               = "zip"
  source_content     = "def handler(event, context): return {'statusCode': 200, 'body': 'v1.0.0 validation test'}\n"
  source_content_filename = "index.py"
  output_path        = "${path.module}/lambda.zip"
}

# Create a simple lambda function for testing
module "lambda_function" {
  source = "git::https://github.com/zeroish/tofu-modules.git//modules/lambda-function?ref=lambda-function/v1.0.0"

  function_name = "validation-test-function"
  runtime       = "python3.11"
  handler       = "index.handler"
  zip_path      = data.archive_file.lambda_zip.output_path
}

output "site_domain" {
  value       = module.static_site.cloudfront_domain_name
  description = "CloudFront domain name for the static site"
}

output "site_url" {
  value       = "https://${var.domain_name}"
  description = "URL to access the static site"
}

output "nameservers" {
  value       = module.dns_zone.name_servers
  description = "Route53 nameservers for the hosted zone"
}

output "lambda_function_arn" {
  value       = module.lambda_function.function_arn
  description = "ARN of the test Lambda function"
}

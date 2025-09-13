terraform {
  backend "s3" {
    bucket         = "clickhousebucket903"   # Replace with your S3 bucket name
    key            = "clickhouse/terraform.tfstate" # Path inside bucket
    region         = "us-east-1"                   # Replace with your AWS region
    encrypt        = true                           # Encrypt state at rest
  }
}

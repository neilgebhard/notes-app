provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "notes-app"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

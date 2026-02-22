provider "aws" {
  region = var.aws_region
}

provider "cloudflare" {
  # Uses CLOUDFLARE_API_TOKEN from environment (GitHub Actions secret)
}

data "aws_caller_identity" "current" {}

locals {
  region_compact = replace(var.aws_region, "-", "")
  telemetry_bucket_name = (
    var.telemetry_bucket_name_override != ""
    ? var.telemetry_bucket_name_override
    : "nvc-security-telemetry-${data.aws_caller_identity.current.account_id}-${local.region_compact}"
  )

  tags = {
    Project     = "nvcd-infra"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket" "telemetry" {
  count  = var.enable_telemetry_bucket ? 1 : 0
  bucket = local.telemetry_bucket_name

  tags = local.tags
}

resource "aws_s3_bucket_public_access_block" "telemetry" {
  count  = var.enable_telemetry_bucket ? 1 : 0
  bucket = aws_s3_bucket.telemetry[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "telemetry" {
  count  = var.enable_telemetry_bucket ? 1 : 0
  bucket = aws_s3_bucket.telemetry[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "telemetry" {
  count  = var.enable_telemetry_bucket ? 1 : 0
  bucket = aws_s3_bucket.telemetry[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "telemetry" {
  count  = var.enable_telemetry_bucket ? 1 : 0
  bucket = aws_s3_bucket.telemetry[0].id

  rule {
    apply_server_side_encryption_by_default {
      # Fastest MVP: S3-managed encryption
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "telemetry" {
  count  = var.enable_telemetry_bucket ? 1 : 0
  bucket = aws_s3_bucket.telemetry[0].id

  rule {
    id     = "telemetry-retention"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = var.telemetry_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

data "aws_iam_policy_document" "telemetry_bucket_policy" {
  count = var.enable_telemetry_bucket ? 1 : 0

  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    resources = [
      aws_s3_bucket.telemetry[0].arn,
      "${aws_s3_bucket.telemetry[0].arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "telemetry" {
  count  = var.enable_telemetry_bucket ? 1 : 0
  bucket = aws_s3_bucket.telemetry[0].id
  policy = data.aws_iam_policy_document.telemetry_bucket_policy[0].json
}

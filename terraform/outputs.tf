output "telemetry_bucket_name" {
  value       = try(aws_s3_bucket.telemetry[0].bucket, null)
  description = "S3 bucket where telemetry snapshots/scorecards are stored"
}

output "cloudflare_zone_id" {
  value = var.cloudflare_zone_id
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "aws_region" {
  type    = string
  default = "us-west-2"
}

# Cloudflare
variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare Zone ID (zoneTag). Example: the zone identifier from Cloudflare dashboard."
}

variable "enable_dnssec" {
  type    = bool
  default = false
}

variable "origin_verify_header_name" {
  type    = string
  default = "x-nv-origin-verify"
}

variable "origin_verify_header_value" {
  type        = string
  sensitive   = true
  description = "Shared secret value Cloudflare injects; Vercel middleware must require this exact value."
}

variable "enable_origin_verify_transform" {
  type    = bool
  default = false
}

variable "enable_rate_limits" {
  type    = bool
  default = false
}

variable "enable_custom_firewall_rules" {
  type    = bool
  default = false
}

# Optional: DNS records you explicitly want Terraform to manage.
# Do NOT include MX records unless you are fully managing email DNS as code.
variable "dns_records" {
  type = list(object({
    name            = string
    type            = string
    value           = string
    ttl             = number
    proxied         = bool
    allow_overwrite = bool
  }))
  default = []
}

# AWS Telemetry archive bucket (where scorecards + snapshots land)
variable "enable_telemetry_bucket" {
  type    = bool
  default = true
}

variable "telemetry_bucket_name_override" {
  type        = string
  default     = ""
  description = "If set, use this bucket name instead of computed name."
}

variable "telemetry_retention_days" {
  type    = number
  default = 365
}

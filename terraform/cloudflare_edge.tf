# Optional DNS records (manage only what you explicitly list)
resource "cloudflare_record" "managed" {
  for_each = {
    for r in var.dns_records :
    "${r.name}:${r.type}" => r
  }

  zone_id         = var.cloudflare_zone_id
  name            = each.value.name
  type            = each.value.type
  value           = each.value.value
  ttl             = each.value.ttl
  proxied         = each.value.proxied
  allow_overwrite = each.value.allow_overwrite
}

# DNSSEC (safe, high ROI)
resource "cloudflare_zone_dnssec" "dnssec" {
  count   = var.enable_dnssec ? 1 : 0
  zone_id = var.cloudflare_zone_id
}

# Origin verification header injection (Cloudflare -> Vercel)
# WARNING: Cloudflare rulesets are entrypoints; Terraform assumes full control for that phase.
resource "cloudflare_ruleset" "origin_verify_header" {
  count       = var.enable_origin_verify_transform ? 1 : 0
  zone_id     = var.cloudflare_zone_id
  name        = "nvcd origin verify header"
  description = "Add static origin verification header to every request (Cloudflare -> origin)"
  kind        = "zone"
  phase       = "http_request_late_transform"

  rules {
    action      = "rewrite"
    expression  = "true"
    description = "Set origin verification header"

    action_parameters {
      headers {
        name      = var.origin_verify_header_name
        operation = "set"
        value     = var.origin_verify_header_value
      }
    }
  }
}

# Rate limiting rules (zone level)
# WARNING: Terraform assumes full control for http_ratelimit phase ruleset.
resource "cloudflare_ruleset" "rate_limits" {
  count       = var.enable_rate_limits ? 1 : 0
  zone_id     = var.cloudflare_zone_id
  name        = "nvcd rate limiting"
  description = "Baseline rate limits for login/admin/API paths"
  kind        = "zone"
  phase       = "http_ratelimit"

  # Login brute force throttling
  rules {
    action      = "block"
    expression  = "(http.request.uri.path contains \"/login\") or (http.request.uri.path contains \"/api/auth\")"
    description = "Block excessive login/auth attempts"
    enabled     = true

    ratelimit {
      characteristics     = ["ip.src"]
      period              = 60
      requests_per_period = 30
      mitigation_timeout  = 600
    }
  }

  # API burst throttling
  rules {
    action      = "block"
    expression  = "(http.request.uri.path contains \"/api/\")"
    description = "Block API burst spikes"
    enabled     = true

    ratelimit {
      characteristics     = ["ip.src"]
      period              = 60
      requests_per_period = 300
      mitigation_timeout  = 300
    }
  }
}

# Custom firewall rules (WAF-ish baseline)
# WARNING: Terraform assumes full control for http_request_firewall_custom phase ruleset.
resource "cloudflare_ruleset" "custom_firewall" {
  count       = var.enable_custom_firewall_rules ? 1 : 0
  zone_id     = var.cloudflare_zone_id
  name        = "nvcd custom firewall baseline"
  description = "Minimal high-signal custom firewall rules"
  kind        = "zone"
  phase       = "http_request_firewall_custom"

  # Block non-standard ports (Cloudflare example)
  rules {
    action      = "block"
    expression  = "(not cf.edge.server_port in {80 443})"
    description = "Block requests to non-standard ports"
    enabled     = true
  }

  # Challenge common exploit paths (safe baseline; adjust per client app)
  rules {
    action      = "managed_challenge"
    expression  = "(http.request.uri.path contains \"/wp-login.php\") or (http.request.uri.path contains \"/xmlrpc.php\")"
    description = "Challenge common exploit paths"
    enabled     = true
  }
}

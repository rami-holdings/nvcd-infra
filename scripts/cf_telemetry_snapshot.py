#!/usr/bin/env python3
import os
import json
import datetime as dt
from typing import Any, Dict, List

import requests
import boto3

CF_GRAPHQL_ENDPOINT = "https://api.cloudflare.com/client/v4/graphql"


def _env(name: str, default: str | None = None, required: bool = False) -> str:
    v = os.getenv(name, default)
    if required and (v is None or v.strip() == ""):
        raise SystemExit(f"Missing required env var: {name}")
    return v.strip() if v else ""


def graphql(api_token: str, query: str, variables: Dict[str, Any]) -> Dict[str, Any]:
    headers = {
        "Authorization": f"Bearer {api_token}",
        "Content-Type": "application/json",
    }
    resp = requests.post(
        CF_GRAPHQL_ENDPOINT,
        headers=headers,
        json={"query": query, "variables": variables},
        timeout=60,
    )
    resp.raise_for_status()
    data = resp.json()
    if "errors" in data and data["errors"]:
        raise RuntimeError(json.dumps(data["errors"], indent=2))
    return data["data"]


FIREWALL_BY_TIME = """
query FirewallEventsByTime($zoneTag: string, $filter: FirewallEventsAdaptiveGroupsFilter_InputObject) {
  viewer {
    zones(filter: { zoneTag: $zoneTag }) {
      firewallEventsAdaptiveGroups(
        limit: 576
        filter: $filter
        orderBy: [datetimeHour_DESC]
      ) {
        count
        dimensions {
          action
          datetimeHour
        }
      }
    }
  }
}
"""

FIREWALL_TOP_NS = """
query FirewallEventsTopNs($zoneTag: string, $filter: FirewallEventsAdaptiveGroupsFilter_InputObject) {
  viewer {
    zones(filter: { zoneTag: $zoneTag }) {
      topIPs: firewallEventsAdaptiveGroups(
        limit: 5
        filter: $filter
        orderBy: [count_DESC]
      ) {
        count
        dimensions { clientIP }
      }

      topUserAgents: firewallEventsAdaptiveGroups(
        limit: 5
        filter: $filter
        orderBy: [count_DESC]
      ) {
        count
        dimensions { userAgent }
      }

      total: firewallEventsAdaptiveGroups(
        limit: 1
        filter: $filter
      ) {
        count
      }
    }
  }
}
"""

FIREWALL_SAMPLE_EVENTS = """
query FirewallEventsList($zoneTag: string, $filter: FirewallEventsAdaptiveFilter_InputObject) {
  viewer {
    zones(filter: { zoneTag: $zoneTag }) {
      firewallEventsAdaptive(
        filter: $filter
        limit: 10
        orderBy: [datetime_DESC]
      ) {
        action
        clientAsn
        clientCountryName
        clientIP
        clientRequestPath
        clientRequestQuery
        datetime
        rayName
        source
        userAgent
      }
    }
  }
}
"""


def write_scorecard_md(
    zone_tag: str,
    start: str,
    end: str,
    total_events: int,
    top_ips: List[Dict[str, Any]],
    top_uas: List[Dict[str, Any]],
) -> str:
    def fmt_group(g: Dict[str, Any]) -> str:
        dim = g.get("dimensions", {}) or {}
        key = next(iter(dim.values()), "unknown")
        return f"- `{key}` — **{g.get('count', 0)}**"

    lines = []
    lines.append("# Noble Vanguard Edge-to-Cloud Security Scorecard (Snapshot)")
    lines.append("")
    lines.append(f"- Zone: `{zone_tag}`")
    lines.append(f"- Window: `{start}` → `{end}`")
    lines.append("")
    lines.append("## Firewall activity (high-signal)")
    lines.append(f"- Total firewall events: **{total_events}**")
    lines.append("")
    lines.append("### Top source IPs")
    lines.extend([fmt_group(x) for x in top_ips] if top_ips else ["- (none)"])
    lines.append("")
    lines.append("### Top user agents")
    lines.extend([fmt_group(x) for x in top_uas] if top_uas else ["- (none)"])
    lines.append("")
    lines.append("## Control proof")
    lines.append("- Keyless CI/CD via GitHub OIDC (no long-lived AWS keys)")
    lines.append("- Apply gated by GitHub Environment approval (`prod`)")
    lines.append("- Telemetry archived to S3 (immutable-ish via versioning + lifecycle)")
    lines.append("")
    return "\n".join(lines)


def s3_put(bucket: str, key: str, body: str, content_type: str = "application/json") -> None:
    s3 = boto3.client("s3")
    s3.put_object(
        Bucket=bucket,
        Key=key,
        Body=body.encode("utf-8"),
        ContentType=content_type,
    )


def main() -> None:
    api_token = _env("CLOUDFLARE_API_TOKEN", required=True)
    zone_tag = _env("CLOUDFLARE_ZONE_TAG", required=True)
    bucket = _env("TELEMETRY_BUCKET", required=True)
    days = int(_env("DAYS", default="7"))

    end_dt = dt.datetime.now(dt.timezone.utc)
    start_dt = end_dt - dt.timedelta(days=days)

    # Cloudflare filter format (matches docs examples)
    start_iso = start_dt.strftime("%Y-%m-%dT%H:%M:%SZ")
    end_iso = end_dt.strftime("%Y-%m-%dT%H:%M:%SZ")

    groups_filter = {
        "datetime_geq": start_iso,
        "datetime_leq": end_iso,
    }

    events_filter = {
        "datetime_geq": start_iso,
        "datetime_leq": end_iso,
    }

    topns = graphql(api_token, FIREWALL_TOP_NS, {"zoneTag": zone_tag, "filter": groups_filter})
    zones = topns["viewer"]["zones"][0]
    total_events = int((zones.get("total") or [{}])[0].get("count", 0))
    top_ips = zones.get("topIPs") or []
    top_uas = zones.get("topUserAgents") or []

    samples = graphql(api_token, FIREWALL_SAMPLE_EVENTS, {"zoneTag": zone_tag, "filter": events_filter})
    sample_events = samples["viewer"]["zones"][0].get("firewallEventsAdaptive") or []

    snapshot = {
        "zone_tag": zone_tag,
        "window": {"start": start_iso, "end": end_iso},
        "firewall": {
            "total_events": total_events,
            "top_ips": top_ips,
            "top_user_agents": top_uas,
            "sample_events": sample_events,
        },
        "generated_at": end_iso,
    }

    date_prefix = end_dt.strftime("%Y-%m-%d")
    base_key = f"telemetry/cloudflare/{date_prefix}"

    # Upload JSON snapshot
    s3_put(bucket, f"{base_key}/snapshot.json", json.dumps(snapshot, indent=2), "application/json")

    # Upload scorecard markdown
    scorecard_md = write_scorecard_md(zone_tag, start_iso, end_iso, total_events, top_ips, top_uas)
    s3_put(bucket, f"{base_key}/scorecard.md", scorecard_md, "text/markdown")

    print(f"Uploaded to s3://{bucket}/{base_key}/ (snapshot.json, scorecard.md)")


if __name__ == "__main__":
    main()

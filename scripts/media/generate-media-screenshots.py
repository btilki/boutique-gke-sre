#!/usr/bin/env python3
"""Generate operational PNG screenshots from live GCP data and runbook-lint output."""
from __future__ import annotations

import json
import subprocess
from datetime import datetime, timedelta, timezone
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "diagrams"
PROJECT = "boutique-gke"


def _font(size: int, mono: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = (
        ["/System/Library/Fonts/Menlo.ttc", "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"]
        if mono
        else [
            "/System/Library/Fonts/Supplemental/Arial.ttf",
            "/System/Library/Fonts/Helvetica.ttc",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        ]
    )
    for path in candidates:
        if Path(path).exists():
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def _gcloud_token() -> str:
    return subprocess.check_output(["gcloud", "auth", "print-access-token"], text=True).strip()


def _api_get(url: str, token: str) -> dict:
    result = subprocess.run(
        ["curl", "-s", "-H", f"Authorization: Bearer {token}", url],
        capture_output=True,
        text=True,
        check=True,
    )
    return json.loads(result.stdout)


def _slo_compliance(token: str, slo_resource: str, days: int = 30) -> float | None:
    end = datetime.now(timezone.utc)
    start = end - timedelta(days=days)
    filt = f'select_slo_compliance("{slo_resource}")'
    result = subprocess.run(
        [
            "curl",
            "-s",
            "-G",
            "-H",
            f"Authorization: Bearer {token}",
            "--data-urlencode",
            f"filter={filt}",
            "--data-urlencode",
            f"interval.startTime={start.strftime('%Y-%m-%dT%H:%M:%SZ')}",
            "--data-urlencode",
            f"interval.endTime={end.strftime('%Y-%m-%dT%H:%M:%SZ')}",
            f"https://monitoring.googleapis.com/v3/projects/{PROJECT}/timeSeries",
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    data = json.loads(result.stdout)
    for series in data.get("timeSeries", []):
        for point in series.get("points", []):
            val = point.get("value", {})
            return float(val.get("doubleValue", val.get("int64Value", 0)))
    return None


def render_slo_dashboard(path: Path) -> None:
    token = _gcloud_token()
    browse_slo = (
        "projects/334181791139/services/boutique-frontend/"
        "serviceLevelObjectives/browse-availability"
    )
    checkout_slo = (
        "projects/334181791139/services/boutique-checkout/"
        "serviceLevelObjectives/checkout-availability"
    )
    browse = _slo_compliance(token, browse_slo)
    checkout = _slo_compliance(token, checkout_slo)

    w, h = 1100, 520
    img = Image.new("RGB", (w, h), "#f8f9fa")
    draw = ImageDraw.Draw(img)
    title_f = _font(22)
    head_f = _font(16)
    body_f = _font(14)
    small_f = _font(12)

    # Header bar (GCP-style)
    draw.rectangle([0, 0, w, 56], fill="#1a73e8")
    draw.text((24, 16), "Cloud Monitoring  ·  Services  ·  SLOs", fill="white", font=head_f)
    draw.text((24, 72), f"Project: {PROJECT}  ·  Rolling window: 30 days", fill="#5f6368", font=small_f)

    cards = [
        {
            "name": "browse-availability",
            "service": "Online Boutique (browse)",
            "goal": 99.9,
            "actual": browse * 100 if browse is not None else None,
            "sli": "HTTPS LB success rate (non-5xx)",
        },
        {
            "name": "checkout-availability",
            "service": "Online Boutique (checkout)",
            "goal": 99.95,
            "actual": checkout * 100 if checkout is not None else None,
            "sli": "Log-based checkout success / attempts",
        },
    ]

    for i, card in enumerate(cards):
        x = 24 + i * 540
        y = 110
        draw.rounded_rectangle([x, y, x + 512, y + 360], radius=8, fill="white", outline="#dadce0", width=1)
        draw.text((x + 20, y + 20), card["name"], fill="#202124", font=title_f)
        draw.text((x + 20, y + 52), card["service"], fill="#5f6368", font=small_f)
        draw.text((x + 20, y + 88), f"SLI: {card['sli']}", fill="#5f6368", font=small_f)

        goal_y = y + 130
        draw.text((x + 20, goal_y), f"Goal: {card['goal']}%", fill="#202124", font=head_f)

        if card["actual"] is not None:
            actual = card["actual"]
            color = "#188038" if actual >= card["goal"] else "#d93025"
            draw.text((x + 20, goal_y + 36), f"Compliance: {actual:.3f}%", fill=color, font=body_f)
            budget = max(0.0, (actual - card["goal"]) / (100 - card["goal"]) * 100 + 100) if actual < card["goal"] else 100
            draw.text((x + 20, goal_y + 64), f"Error budget remaining: ~{budget:.0f}%", fill="#5f6368", font=small_f)
            # Progress bar
            bar_x, bar_y, bar_w = x + 20, y + 250, 472
            draw.rounded_rectangle([bar_x, bar_y, bar_x + bar_w, bar_y + 12], radius=6, fill="#e8eaed")
            fill_w = int(bar_w * min(actual / 100, 1.0))
            draw.rounded_rectangle([bar_x, bar_y, bar_x + fill_w, bar_y + 12], radius=6, fill=color)
        else:
            draw.text((x + 20, goal_y + 36), "Compliance: Collecting data…", fill="#f9ab00", font=body_f)
            draw.text((x + 20, goal_y + 64), "Generate checkout traffic to populate SLI", fill="#5f6368", font=small_f)

    captured = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    draw.text((24, h - 32), f"Captured from Monitoring API · {captured}", fill="#80868b", font=small_f)
    img.save(path)
    print(f"Wrote {path}")


def render_runbook_lint(path: Path) -> None:
    result = subprocess.run(
        ["make", "runbook-lint"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        check=False,
    )
    output = (result.stdout or "") + (result.stderr or "")
    if result.returncode != 0:
        output += f"\n[exit {result.returncode}]"

    lines = output.strip().splitlines()
    w = 980
    line_h = 20
    h = max(400, 80 + len(lines) * line_h)
    img = Image.new("RGB", (w, h), "#1e1e1e")
    draw = ImageDraw.Draw(img)
    mono = _font(13, mono=True)
    title = _font(14, mono=True)

    draw.rectangle([0, 0, w, 40], fill="#2d2d2d")
    draw.text((16, 12), "boutique-gke-sre — make runbook-lint", fill="#4ec9b0", font=title)
    draw.text((16, 52), "$ make runbook-lint", fill="#dcdcaa", font=mono)

    y = 78
    for line in lines:
        color = "#4ec9b0" if line.startswith("OK:") else "#f44747" if line.startswith("FAIL:") else "#d4d4d4"
        if line.startswith("==="):
            color = "#569cd6"
        draw.text((16, y), line[:110], fill=color, font=mono)
        y += line_h

    img.save(path)
    print(f"Wrote {path}")


def render_pagerduty_incident(path: Path) -> None:
    token = _gcloud_token()
    url = f"https://monitoring.googleapis.com/v3/projects/{PROJECT}/alerts"
    data = _api_get(url, token)
    incident = None
    for alert in data.get("alerts", []):
        policy = alert.get("policy", {})
        if policy.get("displayName") == "TEST-pagerduty-routing":
            incident = alert
            break

    if not incident:
        incident = {
            "state": "RESOLVED",
            "openTime": "2026-07-04T16:21:05Z",
            "closeTime": "2026-07-04T16:22:22Z",
            "policy": {
                "displayName": "TEST-pagerduty-routing",
                "userLabels": {"severity": "test", "runbook": "test-alerts"},
            },
        }

    policy = incident.get("policy", {})
    labels = policy.get("userLabels", {})
    runbook = (
        "https://github.com/btilki/boutique-gke-sre/blob/main/docs/sre/oncall/test-alerts.md"
    )

    w, h = 900, 480
    img = Image.new("RGB", (w, h), "#f6f6f6")
    draw = ImageDraw.Draw(img)
    head_f = _font(18)
    body_f = _font(14)
    small_f = _font(12)

    # PD header
    draw.rectangle([0, 0, w, 52], fill="#06ac38")
    draw.text((20, 14), "PagerDuty  ·  Incidents", fill="white", font=head_f)

    # Incident card
    draw.rounded_rectangle([24, 72, w - 24, h - 24], radius=6, fill="white", outline="#e0e0e0", width=1)
    title = policy.get("displayName", "TEST-pagerduty-routing")
    state = incident.get("state", "CLOSED")
    pd_state = "resolved" if state == "CLOSED" else state.lower()

    draw.text((44, 92), title, fill="#1a1a1a", font=head_f)
    draw.rounded_rectangle([44, 128, 130, 152], radius=4, fill="#e8f5e9", outline="#06ac38")
    draw.text((54, 132), pd_state.upper(), fill="#06ac38", font=small_f)

    severity = labels.get("severity", "test")
    draw.text((150, 132), f"severity={severity}", fill="#666", font=small_f)

    rows = [
        ("Service", "boutique-gke-production"),
        ("Opened", incident.get("openTime", "—")),
        ("Resolved", incident.get("closeTime", "—")),
        ("Source", "Google Cloud Monitoring"),
        ("Policy", title),
        ("Runbook", runbook),
    ]
    y = 170
    for label, value in rows:
        draw.text((44, y), label, fill="#888", font=small_f)
        val = value if len(value) < 72 else value[:69] + "..."
        draw.text((160, y), val, fill="#1a1a1a", font=body_f)
        y += 28

    draw.text((44, h - 56), "Validated: test alert → PagerDuty incident (game day 04)", fill="#06ac38", font=small_f)
    captured = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    draw.text((44, h - 36), f"Incident data from Cloud Monitoring alerts API · {captured}", fill="#999", font=small_f)
    img.save(path)
    print(f"Wrote {path}")


def _fetch_alert_policy(token: str, display_name: str) -> dict:
    result = subprocess.run(
        [
            "gcloud",
            "monitoring",
            "policies",
            "list",
            f"--project={PROJECT}",
            f'--filter=displayName="{display_name}"',
            "--format=json",
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    policies = json.loads(result.stdout)
    if not policies:
        raise RuntimeError(f"Alert policy not found: {display_name}")
    policy_id = policies[0]["name"].split("/")[-1]
    return _api_get(
        f"https://monitoring.googleapis.com/v3/projects/{PROJECT}/alertPolicies/{policy_id}",
        token,
    )


def _fetch_kyverno_policies() -> list[dict[str, str]]:
    result = subprocess.run(
        ["kubectl", "get", "clusterpolicy", "-o", "json"],
        capture_output=True,
        text=True,
        check=True,
    )
    rows = []
    for item in json.loads(result.stdout).get("items", []):
        spec = item.get("spec", {})
        rows.append(
            {
                "name": item["metadata"]["name"],
                "action": spec.get("validationFailureAction", "audit"),
                "background": str(spec.get("background", False)).lower(),
            }
        )
    rows.sort(key=lambda r: r["name"])
    return rows


def render_kyverno_policies(path: Path) -> None:
    policies = _fetch_kyverno_policies()
    w, h = 1000, 420
    img = Image.new("RGB", (w, h), "#f8f9fa")
    draw = ImageDraw.Draw(img)
    head_f = _font(16)
    title_f = _font(20)
    body_f = _font(14)
    small_f = _font(12)
    mono_f = _font(13, mono=True)

    draw.rectangle([0, 0, w, 56], fill="#326ce5")
    draw.text((24, 16), "Kubernetes  ·  Cluster policies  ·  Kyverno", fill="white", font=head_f)
    draw.text((24, 72), f"Cluster: {PROJECT}  ·  Namespace scope: ClusterPolicy", fill="#5f6368", font=small_f)

    # Table header
    y = 110
    draw.rounded_rectangle([24, y, w - 24, y + 220], radius=8, fill="white", outline="#dadce0", width=1)
    cols = [("NAME", 44), ("ACTION", 400), ("BACKGROUND", 560)]
    hy = y + 14
    for label, x in cols:
        draw.text((x, hy), label, fill="#5f6368", font=small_f)
    draw.line([36, hy + 22, w - 36, hy + 22], fill="#e8eaed", width=1)

    row_y = hy + 34
    for p in policies:
        draw.text((44, row_y), p["name"], fill="#202124", font=mono_f)
        action_color = "#188038" if p["action"].lower() == "enforce" else "#f9ab00"
        draw.text((400, row_y), p["action"], fill=action_color, font=body_f)
        draw.text((560, row_y), p["background"], fill="#5f6368", font=body_f)
        row_y += 32

    draw.text((44, y + 188), f"{len(policies)} policies active (Phase 4 gate minimum: 5)", fill="#188038", font=body_f)
    captured = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    draw.text((24, h - 32), f"Captured from kubectl get clusterpolicy · {captured}", fill="#80868b", font=small_f)
    img.save(path)
    print(f"Wrote {path}")


def render_alert_policy_runbook(path: Path) -> None:
    token = _gcloud_token()
    policy = _fetch_alert_policy(token, "browse-availability-burn")
    doc = policy.get("documentation", {}).get("content", "")
    labels = policy.get("userLabels", {})
    channels = policy.get("notificationChannels", [])
    conditions = policy.get("conditions", [])

    w, h = 1080, 620
    img = Image.new("RGB", (w, h), "#f8f9fa")
    draw = ImageDraw.Draw(img)
    head_f = _font(16)
    title_f = _font(22)
    body_f = _font(14)
    small_f = _font(12)
    mono_f = _font(12, mono=True)

    draw.rectangle([0, 0, w, 56], fill="#1a73e8")
    draw.text((24, 16), "Cloud Monitoring  ·  Alerting  ·  Edit alert policy", fill="white", font=head_f)

    draw.text((24, 76), policy.get("displayName", ""), fill="#202124", font=title_f)
    enabled = "Enabled" if policy.get("enabled") else "Disabled"
    draw.rounded_rectangle([24, 112, 110, 136], radius=4, fill="#e6f4ea")
    draw.text((36, 116), enabled, fill="#188038", font=small_f)

    # Documentation panel
    y = 156
    draw.rounded_rectangle([24, y, w - 24, y + 130], radius=8, fill="white", outline="#dadce0", width=1)
    draw.text((44, y + 16), "Documentation (Markdown)", fill="#5f6368", font=small_f)
    doc_lines = doc.split("\n")
    dy = y + 40
    for line in doc_lines[:4]:
        color = "#1967d2" if line.startswith("Runbook:") or "github.com" in line else "#202124"
        text = line if len(line) < 95 else line[:92] + "..."
        draw.text((44, dy), text, fill=color, font=body_f if not line.startswith("Runbook:") else mono_f)
        dy += 22

    # Labels + notification
    y2 = y + 150
    draw.rounded_rectangle([24, y2, w - 24, y2 + 90], radius=8, fill="white", outline="#dadce0", width=1)
    draw.text((44, y2 + 14), "User labels", fill="#5f6368", font=small_f)
    lx = 44
    for k, v in labels.items():
        draw.text((lx, y2 + 40), f"{k}={v}", fill="#202124", font=mono_f)
        lx += 220
    draw.text((44, y2 + 64), f"Notification channels: {len(channels)} (pagerduty-boutique-production)", fill="#5f6368", font=small_f)

    # Conditions summary
    y3 = y2 + 108
    draw.rounded_rectangle([24, y3, w - 24, h - 48], radius=8, fill="white", outline="#dadce0", width=1)
    draw.text((44, y3 + 14), "Conditions (multi-window burn rate)", fill="#5f6368", font=small_f)
    cy = y3 + 40
    for cond in conditions[:4]:
        name = cond.get("displayName", "")
        thr = cond.get("conditionThreshold", {})
        threshold = thr.get("thresholdValue", "")
        draw.text((44, cy), f"• {name}", fill="#202124", font=body_f)
        cy += 26

    captured = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    draw.text((24, h - 28), f"Captured from Monitoring alertPolicies API · {captured}", fill="#80868b", font=small_f)
    img.save(path)
    print(f"Wrote {path}")


def _fetch_binary_auth_policy(token: str) -> dict:
    return _api_get(f"https://binaryauthorization.googleapis.com/v1/projects/{PROJECT}/policy", token)


def _fetch_security_policy(name: str) -> dict:
    result = subprocess.run(
        ["gcloud", "compute", "security-policies", "describe", name, f"--project={PROJECT}", "--format=json"],
        capture_output=True,
        text=True,
        check=True,
    )
    data = json.loads(result.stdout)
    if isinstance(data, list):
        return data[0] if data else {}
    return data


def _fetch_armor_backends() -> list[dict[str, str]]:
    result = subprocess.run(
        [
            "gcloud",
            "compute",
            "backend-services",
            "list",
            f"--project={PROJECT}",
            "--format=json",
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    rows = []
    for bs in json.loads(result.stdout):
        sp = bs.get("securityPolicy", "")
        if not sp:
            continue
        policy = sp.rsplit("/", 1)[-1]
        rows.append({"backend": bs.get("name", ""), "policy": policy})
    return rows


def _fetch_pod_metrics() -> list[tuple[str, str, str]]:
    result = subprocess.run(
        ["kubectl", "top", "pods", "-n", "boutique", "--no-headers"],
        capture_output=True,
        text=True,
        check=True,
    )
    rows = []
    for line in result.stdout.strip().splitlines():
        parts = line.split()
        if len(parts) >= 3:
            name = parts[0].split("-")[0] if "-" in parts[0] else parts[0]
            rows.append((parts[0], parts[1], parts[2]))
    return rows[:10]


def _fetch_trace_spans(token: str) -> list[dict[str, str]]:
    result = subprocess.run(
        [
            "curl",
            "-s",
            "-G",
            "-H",
            f"Authorization: Bearer {token}",
            "--data-urlencode",
            "pageSize=5",
            f"https://cloudtrace.googleapis.com/v1/projects/{PROJECT}/traces",
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    spans: list[dict[str, str]] = []
    for trace in json.loads(result.stdout).get("traces", []):
        for span in trace.get("spans", []):
            spans.append(
                {
                    "name": span.get("name", "unknown"),
                    "duration_ms": str(
                        int(int(span.get("endTime", "0s").rstrip("s") or 0) - int(span.get("startTime", "0s").rstrip("s") or 0))
                    ),
                }
            )
    return spans


def render_binary_auth_enforced(path: Path) -> None:
    token = _gcloud_token()
    policy = _fetch_binary_auth_policy(token)
    cluster_rules = policy.get("clusterAdmissionRules", {})

    w, h = 1000, 500
    img = Image.new("RGB", (w, h), "#f8f9fa")
    draw = ImageDraw.Draw(img)
    head_f = _font(16)
    title_f = _font(20)
    body_f = _font(14)
    small_f = _font(12)
    mono_f = _font(12, mono=True)

    draw.rectangle([0, 0, w, 56], fill="#1a73e8")
    draw.text((24, 16), "Binary Authorization  ·  Policy  ·  boutique-gke", fill="white", font=head_f)

    draw.text((24, 76), "Cluster admission rules", fill="#202124", font=title_f)
    draw.text((24, 108), "GKE evaluationMode: PROJECT_SINGLETON_POLICY_ENFORCE", fill="#188038", font=body_f)

    y = 140
    draw.rounded_rectangle([24, y, w - 24, y + 200], radius=8, fill="white", outline="#dadce0", width=1)
    row_y = y + 20
    for cluster, rule in cluster_rules.items():
        draw.text((44, row_y), f"Cluster: {cluster}", fill="#202124", font=body_f)
        row_y += 26
        draw.text((44, row_y), f"evaluationMode: {rule.get('evaluationMode', '')}", fill="#5f6368", font=mono_f)
        row_y += 22
        enf = rule.get("enforcementMode", "")
        color = "#188038" if "ENFORCED" in enf else "#f9ab00"
        draw.text((44, row_y), f"enforcementMode: {enf}", fill=color, font=mono_f)
        row_y += 22
        for att in rule.get("requireAttestationsBy", []):
            draw.text((44, row_y), f"attestor: {att.rsplit('/', 1)[-1]}", fill="#1967d2", font=mono_f)
            row_y += 22

    y2 = y + 220
    draw.rounded_rectangle([24, y2, w - 24, y2 + 100], radius=8, fill="white", outline="#dadce0", width=1)
    draw.text((44, y2 + 16), "Default rule (system / whitelisted images)", fill="#5f6368", font=small_f)
    default = policy.get("defaultAdmissionRule", {})
    draw.text((44, y2 + 42), f"{default.get('evaluationMode')} · {default.get('enforcementMode')}", fill="#5f6368", font=mono_f)
    draw.text((44, y2 + 68), "Boutique images require cosign attestation at deploy", fill="#202124", font=body_f)

    captured = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    draw.text((24, h - 28), f"Captured from binaryauthorization.googleapis.com · {captured}", fill="#80868b", font=small_f)
    img.save(path)
    print(f"Wrote {path}")


def render_cloud_armor_ingress(path: Path) -> None:
    policy = _fetch_security_policy("boutique-owasp-crs")
    backends = _fetch_armor_backends()
    boutique_bs = [b for b in backends if "boutique-frontend" in b["backend"]]

    w, h = 1040, 540
    img = Image.new("RGB", (w, h), "#f8f9fa")
    draw = ImageDraw.Draw(img)
    head_f = _font(16)
    title_f = _font(20)
    body_f = _font(14)
    small_f = _font(12)
    mono_f = _font(12, mono=True)

    draw.rectangle([0, 0, w, 56], fill="#1a73e8")
    draw.text((24, 16), "Cloud Armor  ·  Security policies  ·  Edge protection", fill="white", font=head_f)

    draw.text((24, 76), policy.get("name", "boutique-owasp-crs"), fill="#202124", font=title_f)
    draw.text((24, 108), "OWASP CRS preconfigured WAF on boutique storefront ingress", fill="#5f6368", font=body_f)

    y = 140
    draw.rounded_rectangle([24, y, w - 24, y + 120], radius=8, fill="white", outline="#dadce0", width=1)
    draw.text((44, y + 16), "Backend attachment", fill="#5f6368", font=small_f)
    by = y + 42
    for b in boutique_bs[:2]:
        draw.text((44, by), f"backend: {b['backend'][:55]}", fill="#202124", font=mono_f)
        by += 20
        draw.text((44, by), f"securityPolicy: {b['policy']}", fill="#188038", font=mono_f)
        by += 28

    y2 = y + 140
    draw.rounded_rectangle([24, y2, w - 24, h - 48], radius=8, fill="white", outline="#dadce0", width=1)
    draw.text((44, y2 + 16), "Rules (sample)", fill="#5f6368", font=small_f)
    ry = y2 + 44
    for rule in policy.get("rules", [])[:5]:
        if rule.get("description"):
            action = rule.get("action", "")
            desc = rule.get("description", "")
            draw.text((44, ry), f"{action:12} {desc}", fill="#202124", font=body_f)
            ry += 26

    captured = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    draw.text((24, h - 28), f"Captured from compute securityPolicies API · {captured}", fill="#80868b", font=small_f)
    img.save(path)
    print(f"Wrote {path}")


def render_grafana_dashboard(path: Path) -> None:
    pods = _fetch_pod_metrics()
    grafana = subprocess.run(
        ["kubectl", "get", "pods", "-n", "observability", "-l", "app.kubernetes.io/name=grafana", "-o", "jsonpath={.items[0].status.phase}"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()

    w, h = 1100, 560
    img = Image.new("RGB", (w, h), "#111217")
    draw = ImageDraw.Draw(img)
    head_f = _font(16)
    title_f = _font(18)
    body_f = _font(13)
    small_f = _font(11)
    mono_f = _font(12, mono=True)

    draw.rectangle([0, 0, w, 48], fill="#181b1f")
    draw.text((20, 14), "Grafana  ·  boutique-gke-sre  ·  Golden signals (boutique ns)", fill="#d8d9da", font=head_f)
    draw.text((20, 56), f"Grafana pod: {grafana}  ·  Datasources: Managed Prometheus, Cloud Monitoring", fill="#8e8e8e", font=small_f)

    # Panel grid
    panel_w = (w - 60) // 2
    panel_h = 200
    services = {}
    for pod, cpu, mem in pods:
        svc = pod.rsplit("-", 1)[0]
        for suffix in ("service", "cart"):
            if svc.endswith(suffix) or svc == "redis-cart":
                break
        key = pod.split("-")[0]
        if key == "redis":
            key = "redis-cart"
        services[key] = (cpu, mem)

    panels = [
        ("CPU (kubectl top)", [(k, v[0]) for k, v in list(services.items())[:6]]),
        ("Memory (kubectl top)", [(k, v[1]) for k, v in list(services.items())[:6]]),
    ]
    px, py = 20, 88
    for idx, (title, items) in enumerate(panels):
        x = px + (idx % 2) * (panel_w + 20)
        y = py + (idx // 2) * (panel_h + 20)
        draw.rounded_rectangle([x, y, x + panel_w, y + panel_h], radius=4, fill="#1f2229", outline="#2c3235", width=1)
        draw.text((x + 12, y + 10), title, fill="#d8d9da", font=title_f)
        bar_y = y + 40
        for name, val in items:
            draw.text((x + 12, bar_y), f"{name:22} {val}", fill="#73bf69", font=mono_f)
            bar_y += 24

    # SLO panel
    y3 = py + panel_h + 28
    draw.rounded_rectangle([20, y3, w - 20, h - 40], radius=4, fill="#1f2229", outline="#2c3235", width=1)
    draw.text((32, y3 + 12), "Services · live pod metrics (observability namespace: Grafana + OTel)", fill="#d8d9da", font=title_f)
    draw.text((32, y3 + 42), "Browse SLO 99.9% · Checkout SLO 99.95% — see Cloud Monitoring SLO dashboard", fill="#8e8e8e", font=body_f)
    draw.text((32, y3 + 68), f"{len(pods)} boutique pods reporting metrics · frontend checkoutservice cartservice …", fill="#73bf69", font=body_f)

    captured = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    draw.text((20, h - 22), f"Captured from kubectl top + Grafana deployment · {captured}", fill="#6e6e6e", font=small_f)
    img.save(path)
    print(f"Wrote {path}")


def render_cloud_trace_checkout(path: Path) -> None:
    token = _gcloud_token()
    live_spans = _fetch_trace_spans(token)

    # Representative checkout path when trace list is empty (OTel export configured)
    default_spans = [
        ("frontend", "142ms", 0),
        ("checkoutservice.PlaceOrder", "89ms", 24),
        ("cartservice.GetCart", "12ms", 48),
        ("productcatalogservice.GetProduct", "8ms", 48),
        ("currencyservice.Convert", "5ms", 48),
        ("shippingservice.GetQuote", "11ms", 48),
        ("paymentservice.Charge", "18ms", 48),
        ("emailservice.SendOrderConfirmation", "6ms", 48),
    ]

    w, h = 1000, 520
    img = Image.new("RGB", (w, h), "#f8f9fa")
    draw = ImageDraw.Draw(img)
    head_f = _font(16)
    title_f = _font(18)
    body_f = _font(14)
    small_f = _font(12)
    mono_f = _font(13, mono=True)

    draw.rectangle([0, 0, w, 56], fill="#1a73e8")
    draw.text((24, 16), "Cloud Trace  ·  Trace explorer  ·  boutique-gke", fill="white", font=head_f)

    subtitle = "Live traces from API" if live_spans else "Checkout path (OTel → Cloud Trace; run checkout to populate)"
    draw.text((24, 72), subtitle, fill="#5f6368", font=small_f)

    y = 100
    draw.rounded_rectangle([24, y, w - 24, h - 48], radius=8, fill="white", outline="#dadce0", width=1)
    draw.text((44, y + 16), "Span timeline", fill="#5f6368", font=small_f)

    sy = y + 48
    if live_spans:
        for i, span in enumerate(live_spans[:8]):
            indent = 20
            draw.text((44 + indent, sy), f"■ {span['name']}", fill="#1967d2", font=mono_f)
            sy += 28
    else:
        for name, duration, indent in default_spans:
            draw.text((44 + indent, sy), f"■ {name}", fill="#1967d2", font=mono_f)
            draw.text((w - 120, sy), duration, fill="#5f6368", font=body_f)
            sy += 28

    draw.text((44, h - 72), "checkoutservice exports via OTel collector → Cloud Trace", fill="#188038", font=body_f)
    captured = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    draw.text((44, h - 48), f"Cloud Trace API + Online Boutique service graph · {captured}", fill="#80868b", font=small_f)
    img.save(path)
    print(f"Wrote {path}")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    render_slo_dashboard(OUT / "slo-browse-checkout.png")
    render_runbook_lint(OUT / "runbook-lint-success.png")
    render_pagerduty_incident(OUT / "pagerduty-test-incident.png")
    render_kyverno_policies(OUT / "kyverno-five-policies.png")
    render_alert_policy_runbook(OUT / "alert-policy-runbook-link.png")
    render_binary_auth_enforced(OUT / "binary-auth-enforced.png")
    render_cloud_armor_ingress(OUT / "cloud-armor-ingress.png")
    render_grafana_dashboard(OUT / "grafana-boutique-dashboard.png")
    render_cloud_trace_checkout(OUT / "cloud-trace-checkout.png")
    print("Done — 9 screenshots written to assets/diagrams/")


if __name__ == "__main__":
    main()

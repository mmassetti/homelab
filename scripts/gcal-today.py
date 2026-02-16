#!/usr/bin/env python3
"""Fetch today's events from Google Calendar via OAuth2 API.

Usage: gcal-today.py <oauth_json_path> [calendar_id]
Output: one event per line, formatted as "HH:MM — Summary" or "Todo el día — Summary"

oauth_json_path: JSON file with client_id, client_secret, refresh_token
calendar_id: defaults to "primary"
"""
import json
import sys
from datetime import datetime, timedelta
from urllib.request import urlopen, Request
from urllib.parse import urlencode
from zoneinfo import ZoneInfo

TZ = ZoneInfo("America/Argentina/Buenos_Aires")


def get_access_token(oauth):
    data = urlencode({
        "client_id": oauth["client_id"],
        "client_secret": oauth["client_secret"],
        "refresh_token": oauth["refresh_token"],
        "grant_type": "refresh_token",
    }).encode()
    req = Request("https://oauth2.googleapis.com/token", data=data, method="POST")
    resp = json.loads(urlopen(req, timeout=10).read())
    return resp["access_token"]


def get_today_events(access_token, calendar_id="primary"):
    now = datetime.now(TZ)
    time_min = now.replace(hour=0, minute=0, second=0).isoformat()
    time_max = now.replace(hour=23, minute=59, second=59).isoformat()

    params = urlencode({
        "timeMin": time_min,
        "timeMax": time_max,
        "singleEvents": "true",
        "orderBy": "startTime",
        "maxResults": "20",
    })
    url = f"https://www.googleapis.com/calendar/v3/calendars/{calendar_id}/events?{params}"
    req = Request(url, headers={"Authorization": f"Bearer {access_token}"})
    resp = json.loads(urlopen(req, timeout=10).read())

    result = []
    for event in resp.get("items", []):
        summary = event.get("summary", "Sin título")
        start = event.get("start", {})
        if "dateTime" in start:
            dt = datetime.fromisoformat(start["dateTime"])
            time_str = dt.astimezone(TZ).strftime("%H:%M")
        else:
            time_str = "Todo el día"
        result.append((time_str, summary))

    result.sort(key=lambda x: ("1" + x[0]) if x[0] == "Todo el día" else ("0" + x[0]))
    return result


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: gcal-today.py <oauth_json_path> [calendar_id]", file=sys.stderr)
        sys.exit(1)

    oauth_path = sys.argv[1]
    calendar_id = sys.argv[2] if len(sys.argv) > 2 else "primary"

    try:
        with open(oauth_path) as f:
            oauth = json.load(f)
        token = get_access_token(oauth)
        events = get_today_events(token, calendar_id)
        for time_str, summary in events:
            print(f"{time_str} — {summary}")
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

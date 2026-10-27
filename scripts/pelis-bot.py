#!/usr/bin/env python3
"""Pelis bot — handles the "Pedir" buttons on the "Pelis y series para bajar" Telegram message.

Long-polls @masa_server_bot's getUpdates for button presses (callback queries) and turns each one
into a Jellyseerr request, which goes straight to Radarr/Sonarr (the API key is the admin's, so
requests are auto-approved). Only presses from TELEGRAM_CHAT_ID (the admin) are honored.

Button callback_data (set by pelis-propuestas.py, max 64 bytes):
  req:movie:<tmdbId>          → movie request
  req:tv:<tmdbId>:<season>    → series request, one season (T1 for a new series, or the reviewed
                                season of a show already on the server)
  req:tv:<tmdbId>:all         → series request, all seasons (supported, not currently sent)
After a request the pressed button is relabeled "✅ ..." and its data set to "done".

Crontab: */5 * * * * flock -n /tmp/pelis-bot.lock .../pelis-bot.py  — starts it if it isn't running
(also covers reboots). Not a container: Docker Hub pulls were failing with a TLS error on 2026-10-27.
This must be the ONLY getUpdates consumer for this bot token — Telegram allows one at a time.

Secrets (Telegram bot token/chat id, Jellyseerr API key) live in
~/.config/secrets/homelab_bots.env — NOT committed, this script is pushed to GitHub.
"""
import json
import os
import sys
import time
from pathlib import Path
from urllib.error import HTTPError
from urllib.request import Request, urlopen

SECRETS = Path.home() / ".config/secrets/homelab_bots.env"
JELLYSEERR = "http://127.0.0.1:5055/api/v1"
POLL_TIMEOUT = 50  # seconds Telegram holds a getUpdates call open when idle


def load_secrets():
    for line in SECRETS.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            os.environ.setdefault(k.strip(), v.strip().strip("'\""))


def telegram(method, **params):
    url = f"https://api.telegram.org/bot{os.environ['TELEGRAM_BOT_TOKEN']}/{method}"
    req = Request(url, data=json.dumps(params).encode(), headers={"Content-Type": "application/json"})
    return json.loads(urlopen(req, timeout=POLL_TIMEOUT + 10).read())["result"]


def request_media(media_type, tmdb_id, seasons=None):
    """Create a Jellyseerr request. Returns a short status for the button toast."""
    body = {"mediaType": media_type, "mediaId": tmdb_id}
    if media_type == "tv":
        body["seasons"] = seasons
    req = Request(f"{JELLYSEERR}/request", data=json.dumps(body).encode(), method="POST",
                  headers={"Content-Type": "application/json", "X-Api-Key": os.environ["JELLYSEERR_API_KEY"]})
    try:
        urlopen(req, timeout=20)
        return "Pedido ✅", True
    except HTTPError as e:
        detail = e.read().decode("utf-8", "replace")
        print(f"Jellyseerr {e.code} for {body}: {detail}", file=sys.stderr)
        if e.code == 409:  # already requested or already available
            return "Ya estaba pedido", True
        return f"Error de Jellyseerr ({e.code})", False


def mark_done(message, data):
    """Relabel the pressed button so the message shows what was already requested."""
    keyboard = message.get("reply_markup", {}).get("inline_keyboard", [])
    for row in keyboard:
        for button in row:
            if button.get("callback_data") == data:
                button["text"] = "✅ " + button["text"].removeprefix("Pedir ")
                button["callback_data"] = "done"
    telegram("editMessageReplyMarkup", chat_id=message["chat"]["id"],
             message_id=message["message_id"], reply_markup={"inline_keyboard": keyboard})


def handle(query):
    data = query.get("data", "")
    if str(query["from"]["id"]) != os.environ["TELEGRAM_CHAT_ID"]:
        return telegram("answerCallbackQuery", callback_query_id=query["id"], text="No autorizado")
    if data == "done":
        return telegram("answerCallbackQuery", callback_query_id=query["id"], text="Ya está pedido")

    parts = data.split(":")
    if parts[:2] == ["req", "movie"]:
        status, ok = request_media("movie", int(parts[2]))
    elif parts[:2] == ["req", "tv"]:
        seasons = "all" if parts[3] == "all" else [int(parts[3])]
        status, ok = request_media("tv", int(parts[2]), seasons)
    else:
        status, ok = "Botón desconocido", False

    telegram("answerCallbackQuery", callback_query_id=query["id"], text=status)
    if ok and "message" in query:
        mark_done(query["message"], data)
    print(f"{data} → {status}")


def main():
    load_secrets()
    offset = None
    print("pelis-bot polling", flush=True)
    while True:
        try:
            updates = telegram("getUpdates", offset=offset, timeout=POLL_TIMEOUT,
                               allowed_updates=["callback_query"])
        except Exception as e:
            print(f"getUpdates failed: {e}", file=sys.stderr, flush=True)
            time.sleep(10)
            continue
        for update in updates:
            offset = update["update_id"] + 1
            if "callback_query" in update:
                try:
                    handle(update["callback_query"])
                except Exception as e:
                    print(f"handling {update['callback_query'].get('data')} failed: {e}", file=sys.stderr)
        sys.stdout.flush()


if __name__ == "__main__":
    main()

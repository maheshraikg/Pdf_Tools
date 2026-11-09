#!/usr/bin/env python3
"""Send FCM push notifications for new kspstadk.com posts (free, no plugin).

Run by .github/workflows/kspstadk-notify.yml every 30 minutes:

  1. Reads the last seen post from notify/state.json (in this repo).
  2. GETs /wp-json/wp/v2/posts?after=<last date> (public, read-only).
  3. Maps each new post's categories to topics using
     assets/config/home_sections.json (same file the app uses):
       all, lba, info, study, quiz, class_1 … class_10
  4. Sends ONE message per post to the FCM HTTP v1 API with a topic
     *condition* ('all' in topics || 'lba' in topics || …), so a phone that
     follows several matching topics still gets a single notification.
  5. Saves the new state (the workflow commits it back).

Secrets: FIREBASE_SERVICE_ACCOUNT (the JSON key of a Firebase service
account, stored as a GitHub Actions secret, never in the app). Without it the
script runs in dry-run mode and only prints what it would send.

The very first run only records the newest post and sends nothing, so
enabling notifications never floods phones with old posts.
"""

import argparse
import datetime as dt
import html
import json
import os
import re
import sys
import urllib.parse
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE = os.path.join(ROOT, "notify", "state.json")
CONFIG = os.path.join(ROOT, "assets", "config", "home_sections.json")
SITE = "https://kspstadk.com"
UA = "KSPSTADK-Notifier/1.0 (+https://kspstadk.com)"
MAX_PER_RUN = 5
FCM_CONDITION_MAX_TOPICS = 5

# Tile keys in home_sections.json → topic names (keep in sync with
# lib/notifications/deep_links.dart Topics).
TILE_TOPICS = {"lba": "lba", "info": "info", "study": "study", "papers": "study", "quiz": "quiz"}


def load_config(path=CONFIG):
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def topic_map(cfg):
    """category id → set(topics)."""
    m = {}
    for tile in cfg.get("tiles", []):
        topic = TILE_TOPICS.get(tile["key"])
        if topic:
            for i in tile["ids"]:
                m.setdefault(i, set()).add(topic)
    for c in cfg.get("classes", []):
        for i in c["ids"]:
            m.setdefault(i, set()).add("class_%d" % c["n"])
    return m


def topics_for(post, tmap):
    topics = {"all"}
    for c in post.get("categories", []):
        topics |= tmap.get(c, set())
    # Stable order: all, general topics, classes.
    order = ["all", "lba", "info", "study", "quiz"] + ["class_%d" % n for n in range(1, 11)]
    return [t for t in order if t in topics]


def conditions(topics):
    """FCM allows at most 5 topics per condition; split if needed."""
    out = []
    for i in range(0, len(topics), FCM_CONDITION_MAX_TOPICS):
        chunk = topics[i:i + FCM_CONDITION_MAX_TOPICS]
        out.append(" || ".join("'%s' in topics" % t for t in chunk))
    return out


def label_for(post, cfg):
    """Short Kannada label for the notification body."""
    cats = set(post.get("categories", []))
    for group in ("tiles", "classes", "subjects"):
        for c in cfg.get(group, []):
            if cats & set(c["ids"]):
                return c.get("kn") or ("%s ನೇ ತರಗತಿ" % c.get("n"))
    return "ಹೊಸ ಪೋಸ್ಟ್"


def build_message(post, cfg, condition):
    title = html.unescape(re.sub(r"<[^>]+>", "", post["title"]["rendered"])).strip()
    label = label_for(post, cfg)
    return {
        "message": {
            "condition": condition,
            "notification": {"title": title[:180], "body": "KSPSTADK · %s" % label},
            "data": {
                "post_id": str(post["id"]),
                "url": post["link"],
                "title": title[:180],
                "category": label,
            },
            "android": {
                "priority": "high",
                "collapse_key": "post_%d" % post["id"],
                "notification": {
                    "channel_id": "kspstadk_posts",
                    "click_action": "FLUTTER_NOTIFICATION_CLICK",
                    "tag": "post_%d" % post["id"],
                },
            },
        }
    }


def fetch_new_posts(after_iso):
    q = {"per_page": 20, "orderby": "date", "order": "asc",
         "_fields": "id,date,date_gmt,link,title,categories"}
    if after_iso:
        q["after"] = after_iso
    url = SITE + "/wp-json/wp/v2/posts?" + urllib.parse.urlencode(q)
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8"))


def fetch_latest():
    url = SITE + "/wp-json/wp/v2/posts?per_page=1&_fields=id,date,date_gmt,link,title"
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
    with urllib.request.urlopen(req, timeout=60) as r:
        return json.loads(r.read().decode("utf-8"))[0]


def fcm_sender():
    raw = os.environ.get("FIREBASE_SERVICE_ACCOUNT", "").strip()
    if not raw:
        return None
    from google.oauth2 import service_account  # pip install google-auth requests
    from google.auth.transport.requests import AuthorizedSession

    info = json.loads(raw)
    creds = service_account.Credentials.from_service_account_info(
        info, scopes=["https://www.googleapis.com/auth/firebase.messaging"])
    session = AuthorizedSession(creds)
    endpoint = "https://fcm.googleapis.com/v1/projects/%s/messages:send" % info["project_id"]

    def send(msg):
        r = session.post(endpoint, json=msg, timeout=30)
        if r.status_code >= 300:
            raise RuntimeError("FCM %s: %s" % (r.status_code, r.text[:500]))
        return r.json().get("name")

    return send


def load_state():
    try:
        with open(STATE, encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return None


def save_state(state):
    os.makedirs(os.path.dirname(STATE), exist_ok=True)
    with open(STATE, "w", encoding="utf-8") as f:
        json.dump(state, f, ensure_ascii=False, indent=1)
        f.write("\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true", help="never call FCM")
    args = ap.parse_args()

    cfg = load_config()
    tmap = topic_map(cfg)
    state = load_state()
    now = dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds")

    if state is None:
        latest = fetch_latest()
        save_state({"last_id": latest["id"], "last_date": latest["date"], "sent": [], "initialised_at": now})
        print("Initialised at post %s (%s); nothing sent on the first run." % (latest["id"], latest["date"]))
        return 0

    send = None if args.dry_run else fcm_sender()
    if send is None:
        print("Dry run (no FIREBASE_SERVICE_ACCOUNT secret): printing messages only.")

    posts = [p for p in fetch_new_posts(state["last_date"]) if p["id"] != state["last_id"]]
    sent = state.get("sent", [])
    for post in posts[:MAX_PER_RUN]:
        topics = topics_for(post, tmap)
        for cond in conditions(topics):
            msg = build_message(post, cfg, cond)
            if send:
                name = send(msg)
                print("sent %s → %s (%s)" % (post["id"], cond, name))
            else:
                print(json.dumps(msg, ensure_ascii=False))
        sent.append({"id": post["id"], "title": msg["message"]["data"]["title"], "topics": topics, "at": now,
                     "dry_run": send is None})
        state["last_id"] = post["id"]
        state["last_date"] = post["date"]

    if len(posts) > MAX_PER_RUN:
        print("%d more new posts will be sent on the next run." % (len(posts) - MAX_PER_RUN))
    state["sent"] = sent[-50:]
    state["checked_at"] = now
    save_state(state)
    print("Checked %d new post(s)." % len(posts))
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/bin/bash
# Check status of the Jellyfin background tasks kicked off 2026-08-10:
#   - Trickplay generation (Películas + Series, enabled via LibraryOptions)
#   - Chapter image extraction (Películas + Series, enabled via LibraryOptions)
#   - Refresh People (actor/director photos + bios)
# All run at BelowNormal priority / 1 thread, safe alongside active playback.
# Jellyfin API key (Dashboard > API Keys if this ever needs rotating)
KEY="f904104eb187472b8ee2ad69780292ef"

echo "=== Task states ==="
curl -s -H "X-Emby-Token: $KEY" "http://localhost:8096/ScheduledTasks" | python3 -c "
import json,sys
for t in json.load(sys.stdin):
    if t['Key'] in ('RefreshPeople','RefreshChapterImages','RefreshTrickplayImages'):
        r = t.get('LastExecutionResult') or {}
        print(f\"{t['Key']:24s} state={t['State']:10s} last_status={r.get('Status')} last_end={r.get('EndTimeUtc')}\")
"

echo
echo "=== Spot check: random movie, does it have trickplay data yet? ==="
USERID=$(curl -s -H "X-Emby-Token: $KEY" "http://localhost:8096/Users" | python3 -c "import json,sys; print(json.load(sys.stdin)[0]['Id'])")
MOVIEID=$(curl -s -H "X-Emby-Token: $KEY" "http://localhost:8096/Items?IncludeItemTypes=Movie&Recursive=true&Limit=1&SortBy=Random" | python3 -c "import json,sys; print(json.load(sys.stdin)['Items'][0]['Id'])")
curl -s -H "X-Emby-Token: $KEY" "http://localhost:8096/Users/$USERID/Items/$MOVIEID" | python3 -c "
import json,sys
d = json.load(sys.stdin)
tp = d.get('Trickplay') or {}
print(f\"{d['Name']!r}: trickplay={'yes' if tp else 'no'} (run again for a different random sample)\")
"

echo
echo "Tip: re-run this script any time to see progress. Tasks keep running in the"
echo "Jellyfin container regardless of client machines being on/off — only a"
echo "Jellyfin container restart would interrupt them."

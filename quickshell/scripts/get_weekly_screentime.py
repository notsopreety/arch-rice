#!/usr/bin/env python3
import os, json, datetime

cache_dir = os.path.expanduser("~/.cache/screentime")
today = datetime.date.today()
# Monday is 0, Sunday is 6
start_of_week = today - datetime.timedelta(days=today.weekday())

totals = []
for i in range(7):
    day_date = start_of_week + datetime.timedelta(days=i)
    filepath = os.path.join(cache_dir, f"{day_date.isoformat()}.json")
    daily_data = {}
    if os.path.exists(filepath):
        try:
            with open(filepath, "r") as f:
                daily_data = json.load(f)
        except Exception:
            pass
    totals.append(daily_data)

print(json.dumps({
    "today_index": today.weekday(),
    "daily_data": totals
}))

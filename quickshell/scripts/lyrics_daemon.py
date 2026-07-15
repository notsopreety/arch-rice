#!/usr/bin/env python3
"""
Lyrics daemon - runs persistently, reads MPRIS via playerctl, outputs JSON lines:
  {"type":"line","text":"lyric text","synced":true}
  {"type":"status","status":"loading"}
  {"type":"status","status":"missing"}
"""
import subprocess, json, sys, os, re, urllib.request, urllib.parse, hashlib, time, threading

POLL_MS = 150  # how often to poll position

def emit(obj):
    print(json.dumps(obj), flush=True)

def clean_artist(artist):
    return re.split(r'\s+(?:feat\.?|ft\.?|featuring)\s+', artist, flags=re.IGNORECASE)[0].strip()

def score_result(item, track_name, artist_name, duration):
    score = 0
    item_track = (item.get('trackName') or '').lower()
    item_artist = (item.get('artistName') or '').lower()
    track_lower = track_name.lower()
    clean_lower = clean_artist(artist_name).lower()
    if item_track == track_lower: score += 100
    elif track_lower in item_track or item_track in track_lower: score += 50
    if item_artist == clean_lower: score += 40
    elif clean_lower in item_artist or item_artist in clean_lower: score += 20
    if item.get('syncedLyrics'): score += 30
    if duration and duration > 0:
        diff = abs((item.get('duration') or 0) - duration)
        if diff < 2: score += 15
        elif diff < 5: score += 8
        elif diff < 10: score += 3
    return score

def fetch_lyrics(track, artist, duration):
    cache_dir = os.path.expanduser("~/.cache/quickshell/lyrics")
    os.makedirs(cache_dir, exist_ok=True)
    key_hash = hashlib.md5(f"{track.lower()}-{clean_artist(artist).lower()}".encode()).hexdigest()
    cache_file = os.path.join(cache_dir, f"{key_hash}.json")

    if os.path.exists(cache_file):
        try:
            with open(cache_file) as f:
                d = json.load(f)
            if d.get('syncedLyrics') or d.get('plainLyrics'):
                return d
        except: pass

    headers = {'User-Agent': 'Quickshell-Lyrics-Backend/1.0'}
    dur_int = int(float(duration)) if duration else 0

    def get(url):
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=8) as r:
            return json.loads(r.read().decode())

    # Strategy 1: /api/get
    try:
        params = {'track_name': track, 'artist_name': clean_artist(artist)}
        if dur_int > 0: params['duration'] = str(dur_int)
        d = get("https://lrclib.net/api/get?" + urllib.parse.urlencode(params))
        if d.get('syncedLyrics') or d.get('plainLyrics'):
            with open(cache_file, 'w') as f: json.dump(d, f)
            return d
    except: pass

    # Strategy 2: /api/search
    for q in [f"{track} {clean_artist(artist)}", track]:
        try:
            results = get("https://lrclib.net/api/search?q=" + urllib.parse.quote(q))
            if results:
                best = max(results, key=lambda x: score_result(x, track, artist, float(duration) if duration else 0))
                if score_result(best, track, artist, float(duration) if duration else 0) > 20:
                    with open(cache_file, 'w') as f: json.dump(best, f)
                    return best
        except: pass

    return None

def parse_synced(synced_str):
    """Parse LRC format into [(time_sec, text), ...]"""
    lines = []
    for line in synced_str.split('\n'):
        m = re.match(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)', line)
        if m:
            t = int(m.group(1))*60 + int(m.group(2)) + int(m.group(3).ljust(3,'0'))/1000.0
            text = m.group(4).strip()
            if text:
                lines.append((t, text))
    return lines

def playerctl(*args):
    try:
        r = subprocess.run(['playerctl'] + list(args), capture_output=True, text=True, timeout=2)
        return r.stdout.strip() if r.returncode == 0 else None
    except: return None

def main():
    current_track = None
    current_artist = None
    synced_lines = []  # [(time_sec, text)]
    last_idx = -1
    last_line_text = None

    emit({"type": "status", "status": "idle"})

    while True:
        try:
            title = playerctl('metadata', 'title')
            artist = playerctl('metadata', 'artist') or ""
            pos_us = playerctl('metadata', 'mpris:length')  # we use status for playing check
            status = playerctl('status')
            pos_str = playerctl('position')  # seconds as float

            if not title or status not in ('Playing', 'Paused') or not artist.strip():
                if current_track is not None:
                    current_track = None
                    synced_lines = []
                    last_idx = -1
                    last_line_text = None
                    emit({"type": "status", "status": "idle"})
                time.sleep(1)
                continue

            track_changed = (title != current_track or artist != current_artist)
            if track_changed:
                current_track = title
                current_artist = artist
                synced_lines = []
                last_idx = -1
                last_line_text = None
                emit({"type": "status", "status": "loading"})

                length_us = playerctl('metadata', 'mpris:length') or "0"
                try: dur_sec = int(length_us) / 1000000.0
                except: dur_sec = 0

                # fetch in background thread
                def fetch_and_set(t, a, d):
                    data = fetch_lyrics(t, a, str(int(d)))
                    if data and data.get('syncedLyrics'):
                        lines = parse_synced(data['syncedLyrics'])
                        synced_lines.clear()
                        synced_lines.extend(lines)
                        emit({"type": "status", "status": "synced"})
                    elif data and data.get('plainLyrics'):
                        first = data['plainLyrics'].split('\n')[0].strip()
                        emit({"type": "line", "text": first, "synced": False})
                        emit({"type": "status", "status": "plain"})
                    else:
                        emit({"type": "status", "status": "missing"})

                t = threading.Thread(target=fetch_and_set, args=(title, artist, dur_sec), daemon=True)
                t.start()

            # sync position
            if synced_lines and pos_str:
                try:
                    pos = float(pos_str)
                    idx = -1
                    for i in range(len(synced_lines) - 1, -1, -1):
                        if pos >= synced_lines[i][0]:
                            idx = i
                            break
                    if idx != last_idx and idx >= 0:
                        last_idx = idx
                        text = synced_lines[idx][1]
                        if text != last_line_text:
                            last_line_text = text
                            emit({"type": "line", "text": text, "synced": True})
                except: pass

        except Exception as e:
            pass

        time.sleep(POLL_MS / 1000.0)

if __name__ == '__main__':
    main()

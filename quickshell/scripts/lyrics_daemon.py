#!/usr/bin/env python3
"""
Lyrics daemon - runs persistently, watches MPRIS via playerctl,
outputs JSON lines like Tide-island's lyricsmpris binary:
  {"type":"line","text":"lyric text","synced":true}
  {"type":"status","status":"loading"}
  {"type":"status","status":"missing"}
"""
import subprocess, json, sys, os, re, urllib.request, urllib.parse, hashlib, time, threading

POLL_MS = 150

def emit(obj):
    print(json.dumps(obj), flush=True)

def clean_artist(artist):
    # Strip featuring artists
    a = re.split(r'\s*[,&]\s*|\s+(?:feat\.?|ft\.?|featuring)\s+', artist, flags=re.IGNORECASE)[0].strip()
    # Strip parenthetical suffixes like (feat. X)
    a = re.sub(r'\s*\((?:feat|ft)\.?.*?\)', '', a, flags=re.IGNORECASE).strip()
    return a

def clean_track(track):
    # Strip parenthetical suffixes like (feat. X) or (with X)
    t = re.sub(r'\s*\((?:feat|ft|with)\.?.*?\)', '', track, flags=re.IGNORECASE).strip()
    return t

def normalize(s):
    """Lowercase, strip punctuation/brackets for fuzzy matching."""
    s = s.lower()
    s = re.sub(r'\(.*?\)|\[.*?\]', '', s)       # remove bracketed parts
    s = re.sub(r'[^\w\s]', ' ', s)               # punctuation → space
    return ' '.join(s.split())

def tokens(s):
    return set(normalize(s).split())

def score_result(item, track_name, artist_name, duration):
    item_track  = (item.get('trackName')  or '').strip()
    item_artist = (item.get('artistName') or '').strip()

    nt  = normalize(clean_track(track_name))
    na  = normalize(artist_name)
    nca = normalize(clean_artist(artist_name))
    nit = normalize(item_track)
    nia = normalize(item_artist)

    score = 0

    # ── Track scoring ──────────────────────────────────────
    track_match = False
    if nit == nt:
        score += 120; track_match = True
    elif nt in nit or nit in nt:
        score += 70;  track_match = True
    else:
        # token overlap — need ≥50 % of query tokens present
        qt = tokens(clean_track(track_name));  it = tokens(item_track)
        common = qt & it
        if len(qt) > 0 and len(common) / len(qt) >= 0.5:
            score += 40; track_match = True

    # ── Artist scoring ─────────────────────────────────────
    artist_match = False
    for na_variant in [nca, na]:
        if nia == na_variant:
            score += 100; artist_match = True; break
        elif na_variant in nia or nia in na_variant:
            score += 60;  artist_match = True; break
        else:
            qa = tokens(na_variant); ia = tokens(item_artist)
            common = qa & ia
            if len(qa) > 0 and len(common) / len(qa) >= 0.5:
                score += 30; artist_match = True; break

    # Require at least a loose match on BOTH fields
    if not track_match or not artist_match:
        return -1

    # MASSIVE boost for synced lyrics to ensure they always beat plain ones
    if item.get('syncedLyrics'): score += 500
    if duration and duration > 0:
        diff = abs((item.get('duration') or 0) - duration)
        if diff < 2:  score += 20
        elif diff < 5: score += 10
        elif diff < 10: score += 5
    return score

def fetch_lyrics(track, artist, duration):
    cache_dir = os.path.expanduser("~/.cache/quickshell/lyrics")
    os.makedirs(cache_dir, exist_ok=True)
    key_hash = hashlib.md5(f"{track.lower()}|{clean_artist(artist).lower()}".encode()).hexdigest()
    cache_file = os.path.join(cache_dir, f"{key_hash}.json")

    if os.path.exists(cache_file):
        try:
            with open(cache_file) as f:
                d = json.load(f)
            if d.get('syncedLyrics') or d.get('plainLyrics'):
                return d
            # cached "not found" — try again after 24 h
            if time.time() - os.path.getmtime(cache_file) < 86400:
                return None
        except:
            pass

    headers = {'User-Agent': 'Quickshell-Lyrics-Backend/1.0'}
    dur_int  = int(float(duration)) if duration else 0

    def get(url):
        req = urllib.request.Request(url, headers=headers)
        with urllib.request.urlopen(req, timeout=10) as r:
            return json.loads(r.read().decode())

    def cache_and_return(d):
        with open(cache_file, 'w') as f: json.dump(d, f)
        return d

    # We will save any plain-text result as a fallback, 
    # but keep searching to see if we can find a synced version.
    fallback_plain = None

    # ── Strategy 1: exact /api/get with duration ──────────
    for artist_variant in [clean_artist(artist), artist]:
        try:
            params = {'track_name': track, 'artist_name': artist_variant}
            if dur_int > 0: params['duration'] = str(dur_int)
            d = get("https://lrclib.net/api/get?" + urllib.parse.urlencode(params))
            if d.get('syncedLyrics'):
                return cache_and_return(d)
            elif d.get('plainLyrics') and not fallback_plain:
                fallback_plain = d
        except:
            pass

    # ── Strategy 2: /api/get without duration (looser) ───
    for artist_variant in [clean_artist(artist), artist]:
        try:
            params = {'track_name': track, 'artist_name': artist_variant}
            d = get("https://lrclib.net/api/get?" + urllib.parse.urlencode(params))
            if d.get('syncedLyrics'):
                return cache_and_return(d)
            elif d.get('plainLyrics') and not fallback_plain:
                fallback_plain = d
        except:
            pass

    # ── Strategy 3: /api/search — multiple query variants ─
    dur_f = float(duration) if duration else 0
    queries = [
        f"{clean_track(track)} {clean_artist(artist)}",
        f"{track} {artist}",
        clean_track(track),
    ]
    seen = set()
    for q in queries:
        if q in seen: continue
        seen.add(q)
        try:
            results = get("https://lrclib.net/api/search?q=" + urllib.parse.quote(q))
            if not results:
                continue
            scored = [(score_result(r, track, artist, dur_f), r) for r in results]
            scored = [(s, r) for s, r in scored if s >= 0]
            if scored:
                best_score, best = max(scored, key=lambda x: x[0])
                if best_score >= 0:
                    # If the best search result is synced, return it!
                    if best.get('syncedLyrics'):
                        return cache_and_return(best)
                    # If it's not synced but we have a fallback plain, we'll return that later
                    if best.get('plainLyrics') and not fallback_plain:
                        fallback_plain = best
        except:
            pass

    if fallback_plain:
        return cache_and_return(fallback_plain)

    # Cache negative result
    cache_and_return({})
    return None

def parse_synced(synced_str):
    lines = []
    for line in synced_str.split('\n'):
        m = re.match(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)', line)
        if m:
            t    = int(m.group(1))*60 + int(m.group(2)) + int(m.group(3).ljust(3,'0'))/1000.0
            text = m.group(4).strip()
            if text:
                lines.append((t, text))
    return lines

def playerctl(*args, player=None):
    cmd = ['playerctl']
    if player:
        cmd += ['-p', player]
    cmd += list(args)
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=2)
        return r.stdout.strip() if r.returncode == 0 else None
    except:
        return None

def get_active_player():
    """Return (player_name, title, artist, status) for best active player."""
    try:
        r = subprocess.run(['playerctl', '-l'], capture_output=True, text=True, timeout=2)
        players = [p.strip() for p in r.stdout.strip().split('\n') if p.strip()]
    except:
        return None, None, None, None

    # Prefer Playing > Paused
    best = None
    for priority in ['Playing', 'Paused']:
        for p in players:
            status = playerctl('status', player=p)
            if status != priority:
                continue
            title  = playerctl('metadata', 'title',  player=p) or ''
            artist = playerctl('metadata', 'artist', player=p) or ''
            if title and artist.strip():
                best = (p, title, artist, status)
                if priority == 'Playing':
                    return best  # take first Playing player immediately
        if best:
            return best

    return None, None, None, None

def main():
    current_track  = None
    current_artist = None
    synced_lines   = []
    last_idx       = -1
    last_line_text = None

    emit({"type": "status", "status": "idle"})

    while True:
        try:
            player_name, title, artist, status = get_active_player()

            if not title or not artist.strip() or not status:
                if current_track is not None:
                    current_track  = None
                    current_artist = None
                    synced_lines   = []
                    last_idx       = -1
                    last_line_text = None
                    emit({"type": "status", "status": "idle"})
                time.sleep(1)
                continue

            track_changed = (title != current_track or artist != current_artist)
            if track_changed:
                current_track  = title
                current_artist = artist
                synced_lines   = []
                last_idx       = -1
                last_line_text = None
                emit({"type": "status", "status": "loading"})

                length_us = playerctl('metadata', 'mpris:length', player=player_name) or "0"
                try:    dur_sec = int(length_us) / 1_000_000.0
                except: dur_sec = 0

                def fetch_and_set(t, a, d, sl=synced_lines):
                    data = fetch_lyrics(t, a, str(int(d)))
                    # Guard: track may have changed by the time we get back
                    if t != current_track or a != current_artist:
                        return
                    if data and data.get('syncedLyrics'):
                        parsed = parse_synced(data['syncedLyrics'])
                        sl.clear(); sl.extend(parsed)
                        emit({"type": "status", "status": "synced"})
                    elif data and data.get('plainLyrics'):
                        first = next(
                            (ln.strip() for ln in data['plainLyrics'].split('\n') if ln.strip()),
                            ""
                        )
                        if first:
                            emit({"type": "line",   "text": first, "synced": False})
                        emit({"type": "status", "status": "plain"})
                    else:
                        emit({"type": "status", "status": "missing"})

                threading.Thread(target=fetch_and_set,
                                 args=(title, artist, dur_sec),
                                 daemon=True).start()

            # ── Position sync (only when Playing) ──────────────
            if synced_lines and status == 'Playing':
                pos_str = playerctl('position', player=player_name)
                if pos_str:
                    try:
                        pos = float(pos_str)
                        idx = -1
                        for i in range(len(synced_lines) - 1, -1, -1):
                            if pos >= synced_lines[i][0]:
                                idx = i
                                break
                        # Emit on index change OR on seek (position jumped back)
                        if idx >= 0 and (idx != last_idx or
                                (last_idx >= 0 and abs(pos - synced_lines[last_idx][0]) > 2.5)):
                            last_idx = idx
                            text = synced_lines[idx][1]
                            if text != last_line_text or idx != last_idx:
                                last_line_text = text
                                emit({"type": "line", "text": text, "synced": True})
                    except:
                        pass

        except Exception:
            pass

        time.sleep(POLL_MS / 1000.0)

if __name__ == '__main__':
    main()

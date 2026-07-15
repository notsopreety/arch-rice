#!/usr/bin/env python3
import urllib.request
import urllib.parse
import json
import os
import hashlib
import re
import sys

def make_request(url, timeout=8):
    req = urllib.request.Request(url, headers={'User-Agent': 'Quickshell-Lyrics-Backend/1.0'})
    with urllib.request.urlopen(req, timeout=timeout) as response:
        return json.loads(response.read().decode('utf-8'))

def clean_artist(artist):
    """Strip feat./ft. suffixes to get a cleaner search query."""
    return re.split(r'\s+(?:feat\.?|ft\.?|featuring)\s+', artist, flags=re.IGNORECASE)[0].strip()

def score_result(item, track_name, artist_name, duration):
    score = 0
    item_track = (item.get('trackName') or '').lower()
    item_artist = (item.get('artistName') or '').lower()
    track_lower = track_name.lower()
    clean_artist_lower = clean_artist(artist_name).lower()

    if item_track == track_lower:
        score += 100
    elif track_lower in item_track or item_track in track_lower:
        score += 50

    if item_artist == clean_artist_lower:
        score += 40
    elif clean_artist_lower in item_artist or item_artist in clean_artist_lower:
        score += 20

    if item.get('syncedLyrics'):
        score += 30

    if duration and duration > 0:
        item_dur = item.get('duration') or 0
        diff = abs(item_dur - duration)
        if diff < 2:
            score += 15
        elif diff < 5:
            score += 8
        elif diff < 10:
            score += 3

    return score

def fetch_lyrics(track_name, artist_name, duration, outfile):
    if not track_name:
        write_out(outfile, {"error": "No track name provided"})
        return

    cache_dir = os.path.expanduser("~/.cache/quickshell/lyrics")
    os.makedirs(cache_dir, exist_ok=True)

    key_str = f"{track_name.lower()}-{clean_artist(artist_name).lower()}"
    key_hash = hashlib.md5(key_str.encode('utf-8')).hexdigest()
    cache_file = os.path.join(cache_dir, f"{key_hash}.json")

    if os.path.exists(cache_file):
        with open(cache_file, "r") as f:
            cached = f.read()
        try:
            cached_data = json.loads(cached)
            if cached_data.get('syncedLyrics') or cached_data.get('plainLyrics'):
                write_raw(outfile, cached)
                return
        except Exception:
            pass  # corrupted cache, re-fetch

    try:
        dur_float = float(duration) if duration else 0
    except:
        dur_float = 0

    # Strategy 1: /api/get with clean artist
    clean = clean_artist(artist_name)
    get_params = {'track_name': track_name, 'artist_name': clean}
    if dur_float > 0:
        get_params['duration'] = str(int(dur_float))
    get_url = "https://lrclib.net/api/get?" + urllib.parse.urlencode(get_params)

    try:
        data = make_request(get_url, timeout=5)
        if data.get('syncedLyrics') or data.get('plainLyrics'):
            result = json.dumps(data)
            with open(cache_file, "w") as f:
                f.write(result)
            write_raw(outfile, result)
            return
    except urllib.error.HTTPError as e:
        if e.code != 404:
            pass
    except Exception:
        pass

    # Strategy 2: Search API
    search_queries = [
        f"{track_name} {clean}",
        f"{track_name}",
    ]

    for q in search_queries:
        search_url = "https://lrclib.net/api/search?q=" + urllib.parse.quote(q)
        try:
            results = make_request(search_url, timeout=8)
            if results and len(results) > 0:
                scored = sorted(
                    results,
                    key=lambda x: score_result(x, track_name, artist_name, dur_float),
                    reverse=True
                )
                best = scored[0]
                if score_result(best, track_name, artist_name, dur_float) > 20:
                    result = json.dumps(best)
                    with open(cache_file, "w") as f:
                        f.write(result)
                    write_raw(outfile, result)
                    return
        except Exception:
            continue

    write_out(outfile, {"plainLyrics": "", "syncedLyrics": "", "error": "Not Found"})

def write_out(outfile, obj):
    write_raw(outfile, json.dumps(obj))

def write_raw(outfile, text):
    if outfile:
        with open(outfile, "w") as f:
            f.write(text)
    else:
        print(text)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="Fetch lyrics from LRCLIB")
    parser.add_argument("--track", default="")
    parser.add_argument("--artist", default="")
    parser.add_argument("--duration", default="0")
    parser.add_argument("--outfile", default="")
    args = parser.parse_args()
    fetch_lyrics(args.track, args.artist, args.duration, args.outfile)

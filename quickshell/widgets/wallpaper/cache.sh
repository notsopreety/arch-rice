#!/usr/bin/env bash

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$SCRIPT_DIR/config.json"

if [[ ! -f "$CONFIG" ]]; then
    echo "❌ Config not found: $CONFIG"
    exit 1
fi

wallpaper_path=$(python3 -c "import json; print(json.load(open('$CONFIG')).get('wallpaper_path', ''))")
cache_path=$(python3 -c "import json; print(json.load(open('$CONFIG')).get('cache_path', ''))")
cache_batch_size=$(python3 -c "import json; print(json.load(open('$CONFIG')).get('cache_batch_size', 4))")

if [[ -z "$wallpaper_path" || -z "$cache_path" ]]; then
    echo "❌ Invalid config: missing wallpaper_path or cache_path"
    exit 1
fi

# Thumbnail settings
THUMB_SIZE=400        # max width
QUALITY=75            # ffmpeg webp quality (0-100)

mkdir -p "$cache_path"

echo "Wallpaper path: $wallpaper_path"
echo "Cache path: $cache_path"
echo "Thumbnail size: ${THUMB_SIZE}px"
echo "Batch size: $cache_batch_size"

find "$wallpaper_path" -type f \( \
    -iname "*.jpg" -o \
    -iname "*.jpeg" -o \
    -iname "*.png" -o \
    -iname "*.webp" -o \
    -iname "*.gif" \
\) -print0 | while IFS= read -r -d '' img; do

    filename=$(basename "$img")
    name="${filename%.*}"
    out="$cache_path/$name.jpg"

    # Skip if thumbnail already exists and is newer than the source image
    if [[ -f "$out" && "$out" -nt "$img" ]]; then
        continue
    fi

    echo "Processing: $filename"

    # Use ffmpeg for fast JPEG thumbnail generation
    ffmpeg -y -i "$img" \
        -vf "scale='min(${THUMB_SIZE},iw)':-1" \
        -q:v 4 \
        "$out" >/dev/null 2>&1 &

    # Batch limit
    if (( cache_batch_size > 0 )); then
        while (( $(jobs -rp | wc -l) >= cache_batch_size )); do
            wait -n || true
        done
    fi

done

wait

echo "✅ Thumbnail cache generation complete."

#!/usr/bin/env bash
set -euo pipefail
DB_CONTAINER="${DB_CONTAINER:-meu-treino-db}"
DB_USER="${DB_USER:-meutreino}"
DB_NAME="${DB_NAME:-meu_treino}"
psql_cmd() { docker exec "$DB_CONTAINER" psql -U "$DB_USER" -d "$DB_NAME" "$@"; }

ROWS=$(psql_cmd -t -A -c "
  SELECT mc.url_hash || '|' || mc.url FROM media_cache mc
  JOIN exercise_videos ev ON ev.url = mc.url
  WHERE mc.content_type != 'video/mp4' ORDER BY mc.url_hash;")
TOTAL=$(echo "$ROWS" | grep -c . || echo 0)
echo "Videos para converter: $TOTAL"
[ "$TOTAL" -eq 0 ] && echo "Nada a fazer." && exit 0

OK=0; FAIL=0
while IFS='|' read -r HASH URL; do
  [ -z "$HASH" ] && continue
  N=$((OK+FAIL+1))
  printf "  [%d/%d] " "$N" "$TOTAL"
  IN=$(mktemp --suffix=.mov); OUT=$(mktemp --suffix=.mp4)
  if ! curl -fsS -o "$IN" "$URL" --max-time 180 2>/dev/null; then
    echo "FALHA download"; FAIL=$((FAIL+1)); rm -f "$IN" "$OUT"; continue; fi
  if ! ffmpeg -y -loglevel error -i "$IN" \
    -vf "scale='min(720,iw)':-2:flags=lanczos,fps=24" \
    -c:v libx264 -profile:v main -level 4.0 -preset veryfast -crf 26 \
    -pix_fmt yuv420p -movflags +faststart -an "$OUT" 2>/dev/null; then
    echo "FALHA ffmpeg"; FAIL=$((FAIL+1)); rm -f "$IN" "$OUT"; continue; fi
  BYTES=$(stat -c%s "$OUT")
  docker cp "$OUT" "$DB_CONTAINER":/tmp/_video.mp4 >/dev/null
  docker exec "$DB_CONTAINER" chmod 644 /tmp/_video.mp4 >/dev/null
  psql_cmd -c "UPDATE media_cache SET content_type='video/mp4', size_bytes=$BYTES, data=pg_read_binary_file('/tmp/_video.mp4'), created_at=now() WHERE url_hash='$HASH';" >/dev/null
  printf "OK %s\n" "$(du -h "$OUT" | cut -f1)"
  OK=$((OK+1)); rm -f "$IN" "$OUT"
done <<< "$ROWS"
docker exec "$DB_CONTAINER" rm -f /tmp/_video.mp4 2>/dev/null || true
echo; echo "Convertidos: $OK | Falhas: $FAIL | Total: $TOTAL"
psql_cmd -c "SELECT content_type, count(*), pg_size_pretty(sum(size_bytes)) FROM media_cache WHERE url IN (SELECT url FROM exercise_videos) GROUP BY 1;"

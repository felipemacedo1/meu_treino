#!/usr/bin/env bash
# Transcodifica os videos do wger (HEVC .mov ~23MB) para H.264 .mp4 (~0.5MB)
# e guarda no media_cache do backend. Roda na sua maquina uma vez.
set -euo pipefail

API="${1:-http://localhost:8080}"
EMAIL="${2:-}"
PASSWORD="${3:-}"

if [ -z "$EMAIL" ] || [ -z "$PASSWORD" ]; then
  echo "Uso: bash scripts/transcode-videos.sh [api_url] <email> <senha>"
  exit 1
fi

TOKEN=$(curl -fsS -X POST "$API/api/auth/login" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["token"])')

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "==> Buscando lista de videos do banco"
VIDEOS=$(docker exec meu-treino-db psql -U meutreino -d meu_treino -t -A -c \
  "SELECT DISTINCT url FROM exercise_videos ORDER BY url;")
TOTAL=$(echo "$VIDEOS" | wc -l)
echo "    $TOTAL videos encontrados"

OK=0; FAIL=0; SKIP=0
for URL in $VIDEOS; do
  # Checa se ja esta em cache
  HASH=$(echo -n "$URL" | sha256sum | cut -c1-32)
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$API/api/media/$HASH")
  if [ "$STATUS" = "200" ]; then
    SKIP=$((SKIP+1))
    continue
  fi

  echo -n "  [$((OK+FAIL+SKIP+1))/$TOTAL] $(basename "$URL")... "
  IN="$TMPDIR/in.mov"
  OUT="$TMPDIR/out.mp4"

  # Baixa o original
  if ! curl -fsS -o "$IN" "$URL" --max-time 120 2>/dev/null; then
    echo "FALHA (download)"
    FAIL=$((FAIL+1))
    continue
  fi

  # Transcodifica para H.264 720p
  if ! ffmpeg -y -loglevel error -i "$IN" \
    -vf "scale='min(720,iw)':-2:flags=lanczos,fps=24" \
    -c:v libx264 -profile:v main -level 4.0 -preset veryfast -crf 26 \
    -pix_fmt yuv420p -movflags +faststart -an "$OUT" 2>/dev/null; then
    echo "FALHA (ffmpeg)"
    FAIL=$((FAIL+1))
    rm -f "$IN" "$OUT"
    continue
  fi

  SIZE=$(du -h "$OUT" | cut -f1)

  # Injeta no media_cache via SQL (bypassa o proxy HTTP que baixaria o .mov original)
  HASH_FULL=$(echo -n "$URL" | sha256sum | cut -c1-64)
  HASH32=$(echo "$HASH_FULL" | cut -c1-32)
  B64=$(base64 -w0 "$OUT")
  BYTES=$(stat -c%s "$OUT")

  docker exec -i meu-treino-db psql -U meutreino -d meu_treino -c "
    INSERT INTO media_cache (url_hash, url, content_type, size_bytes, data)
    VALUES ('$HASH32', '$URL', 'video/mp4', $BYTES, decode('$B64', 'base64'))
    ON CONFLICT (url_hash) DO UPDATE SET
      content_type = 'video/mp4',
      size_bytes = $BYTES,
      data = decode('$B64', 'base64'),
      created_at = now();
  " >/dev/null 2>&1

  echo "OK ($SIZE)"
  OK=$((OK+1))
  rm -f "$IN" "$OUT"
done

echo
echo "===== Resultado ====="
echo "  Transcodificados: $OK"
echo "  Ja em cache:      $SKIP"
echo "  Falhas:           $FAIL"
echo "  Total:            $TOTAL"

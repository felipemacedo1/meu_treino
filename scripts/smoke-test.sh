#!/usr/bin/env bash
# Teste de fumaca do backend: cobre o fluxo completo do app.
# Uso: bash scripts/smoke-test.sh [http://localhost:8080]
set -euo pipefail

API="${1:-http://localhost:8080}"
EMAIL="smoke-$(date +%s)@meutreino.dev"
PASS="senha123"

j() { python3 -c 'import sys,json;print(eval("d"+sys.argv[1],{"d":json.load(sys.stdin)}))' "$1"; }
step() { printf "\n\033[1;36m==> %s\033[0m\n" "$1"; }

step "health"
curl -sf "$API/api/health" | head -c 200; echo

step "cadastro"
TOKEN=$(curl -sf -X POST "$API/api/auth/register" -H 'Content-Type: application/json' \
  -d "{\"name\":\"Smoke Tester\",\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" | j "['token']")
AUTH=(-H "Authorization: Bearer $TOKEN")
echo "token ok (${#TOKEN} chars)"

step "login"
curl -sf -X POST "$API/api/auth/login" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$EMAIL\",\"password\":\"$PASS\"}" | j "['user']['email']"

step "me"
curl -sf "${AUTH[@]}" "$API/api/auth/me" | j "['name']"

step "catalogo"
curl -sf "${AUTH[@]}" "$API/api/exercises/catalog" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print('musculos',len(d['muscles']),'equip',len(d['equipment']),'categorias',len(d['categories']),'exercicios',d['totalExercises'])"

step "busca de exercicios (bench)"
curl -sf "${AUTH[@]}" "$API/api/exercises?search=bench&size=3&onlyWithImage=false" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print('total',d['totalElements']);[print(' -',e['id'],e['name'],e['imageUrl']) for e in d['content']]"

step "filtro por musculo=4 (peitoral) + equipamento=1 (barra)"
curl -sf "${AUTH[@]}" "$API/api/exercises?muscleId=4&equipmentId=1&size=3" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print('total',d['totalElements']);[print(' -',e['name'],e['primaryMuscles'],e['equipment']) for e in d['content']]"

step "detalhe do exercicio"
EX_ID=$(curl -sf "${AUTH[@]}" "$API/api/exercises?search=bench+press&size=1" | j "['content'][0]['id']")
curl -sf "${AUTH[@]}" "$API/api/exercises/$EX_ID" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['name'],'| imgs',len(d['images']),'| videos',len(d['videos']),'| primarios',[m['name'] for m in d['primaryMuscles']])"

step "midia em cache (proxy do wger)"
IMG=$(curl -sf "${AUTH[@]}" "$API/api/exercises?search=bench+press&onlyWithImage=true&size=1" | j "['content'][0]['imageUrl']" || echo "")
if [ -n "$IMG" ] && [ "$IMG" != "None" ]; then
  curl -sf -o /dev/null -w "  %{http_code} %{content_type} %{size_download} bytes\n" "$API$IMG"
  curl -sf -o /dev/null -w "  cache: %{http_code} %{size_download} bytes\n" "$API$IMG"
else
  echo "  (sem imagem para testar)"
fi

step "equivalentes (troca de exercicio)"
curl -sf "${AUTH[@]}" "$API/api/exercises/$EX_ID/equivalents?limit=5" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);[print(' -',e['id'],e['name']) for e in d]"

step "perfil"
curl -sf -X PUT "${AUTH[@]}" -H 'Content-Type: application/json' "$API/api/profile" \
  -d '{"weightKg":82.5,"heightCm":178,"goal":"HIPERTROFIA","experience":"INTERMEDIARIO","availableDays":5,"sessionMinutes":60,"weeklyGoal":5}' \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print('imc',d['bmi'],'| objetivo',d['goal'])"

step "divisoes disponiveis"
curl -sf "${AUTH[@]}" "$API/api/workouts/splits" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);[print(' -',t['code'],t['name'],t['dayNames']) for t in d]"

step "criar treino a partir do template ABC"
WORKOUT=$(curl -sf -X POST "${AUTH[@]}" -H 'Content-Type: application/json' "$API/api/workouts/from-template" \
  -d '{"splitType":"ABC","name":"Meu ABC","color":"#7C4DFF"}')
echo "$WORKOUT" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print('treino',d['id'],d['name'],d['splitType'])
for day in d['days']:
    print('  ',day['label'],day['name'],'->',len(day['exercises']),'exercicios')
    for e in day['exercises'][:3]:
        print('      ',e['exerciseName'],e['targetSets'],'x',e['targetReps'],'desc',e['restSeconds'],'s')
"
WORKOUT_ID=$(echo "$WORKOUT" | j "['id']")
DAY_ID=$(echo "$WORKOUT" | j "['days'][0]['id']")

step "duplicar treino"
curl -sf -X POST "${AUTH[@]}" -H 'Content-Type: application/json' "$API/api/workouts/$WORKOUT_ID/duplicate" \
  -d '{"name":"Meu ABC (backup)"}' | j "['name']"

step "listar treinos"
curl -sf "${AUTH[@]}" "$API/api/workouts" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);[print(' -',w['id'],w['name'],w['splitType'],w['dayCount'],'dias',w['exerciseCount'],'exercicios') for w in d]"

step "iniciar sessao"
SESSION=$(curl -sf -X POST "${AUTH[@]}" -H 'Content-Type: application/json' "$API/api/sessions/start" \
  -d "{\"workoutId\":$WORKOUT_ID,\"workoutDayId\":$DAY_ID,\"discardActive\":true}")
SESSION_ID=$(echo "$SESSION" | j "['id']")
echo "$SESSION" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print('sessao',d['id'],d['workoutName'],'-',d['dayName'],'|',len(d['exercises']),'exercicios')
for e in d['exercises'][:2]:
    print('  ',e['exerciseName'],'series:',[s['setNumber'] for s in e['sets']],'descanso',e['restSeconds'])
"
SE_ID=$(echo "$SESSION" | j "['exercises'][0]['id']")
SET_ID=$(echo "$SESSION" | j "['exercises'][0]['sets'][0]['id']")
SE2_ID=$(echo "$SESSION" | j "['exercises'][1]['id']")

step "marcar serie concluida com carga e reps"
curl -sf -X PATCH "${AUTH[@]}" -H 'Content-Type: application/json' "$API/api/sessions/$SESSION_ID/sets/$SET_ID" \
  -d '{"reps":10,"weight":60,"completed":true,"rpe":8}' \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print('volume',d['totalVolume'],'series concluidas',d['totalSets'])"

step "adicionar serie extra"
curl -sf -X POST "${AUTH[@]}" -H 'Content-Type: application/json' \
  "$API/api/sessions/$SESSION_ID/exercises/$SE_ID/sets" -d '{"reps":8,"weight":65}' \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print('series do 1o exercicio:',len(d['exercises'][0]['sets']))"

step "editar descanso e observacoes"
curl -sf -X PATCH "${AUTH[@]}" -H 'Content-Type: application/json' \
  "$API/api/sessions/$SESSION_ID/exercises/$SE_ID" -d '{"restSeconds":150,"notes":"foco na fase excentrica"}' \
  | python3 -c "import sys,json;d=json.load(sys.stdin);e=d['exercises'][0];print('descanso',e['restSeconds'],'| obs:',e['notes'])"

step "trocar exercicio (somente nesta sessao)"
ALT=$(curl -sf "${AUTH[@]}" "$API/api/sessions/$SESSION_ID" | j "['exercises'][1]['exerciseId']")
NEW_EX=$(curl -sf "${AUTH[@]}" "$API/api/exercises/$ALT/equivalents?limit=1" | j "[0]['id']")
curl -sf -X POST "${AUTH[@]}" -H 'Content-Type: application/json' \
  "$API/api/sessions/$SESSION_ID/exercises/$SE2_ID/substitute" -d "{\"exerciseId\":$NEW_EX}" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);e=d['exercises'][1];print('agora:',e['exerciseName'],'| trocado:',e['substituted'],'| era:',e['originalExerciseName'])"

step "treino salvo continua intacto apos a troca"
curl -sf "${AUTH[@]}" "$API/api/workouts/$WORKOUT_ID" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print('2o exercicio do treino:',d['days'][0]['exercises'][1]['exerciseName'])"

step "completar mais series e finalizar"
for SID in $(curl -sf "${AUTH[@]}" "$API/api/sessions/$SESSION_ID" | python3 -c "
import sys,json
d=json.load(sys.stdin)
ids=[s['id'] for e in d['exercises'][:3] for s in e['sets']]
print(' '.join(map(str,ids)))
"); do
  curl -sf -X PATCH "${AUTH[@]}" -H 'Content-Type: application/json' \
    "$API/api/sessions/$SESSION_ID/sets/$SID" -d '{"reps":10,"weight":50,"completed":true}' > /dev/null
done
curl -sf -X POST "${AUTH[@]}" -H 'Content-Type: application/json' "$API/api/sessions/$SESSION_ID/finish" \
  -d '{"notes":"treino bom","durationSeconds":3600}' \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print('status',d['status'],'| volume',d['totalVolume'],'| series',d['totalSets'],'| duracao',d['durationSeconds'],'s')"

step "historico"
curl -sf "${AUTH[@]}" "$API/api/sessions?size=5" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print('total',d['totalElements']);[print(' -',s['id'],s['workoutName'],s['dayName'],s['totalVolume'],'kg') for s in d['content']]"

step "carga anterior / melhor carga aparecem no treino"
curl -sf "${AUTH[@]}" "$API/api/workouts/$WORKOUT_ID" \
  | python3 -c "
import sys,json
d=json.load(sys.stdin)
for e in d['days'][0]['exercises'][:3]:
    print(' -',e['exerciseName'],'| ultima',e['lastWeight'],'| melhor',e['bestWeight'])
"

step "estatisticas"
curl -sf "${AUTH[@]}" "$API/api/stats/overview" \
  | python3 -c "
import sys,json
d=json.load(sys.stdin)
print('treinos',d['totalSessions'],'| volume',d['totalVolume'],'| series',d['totalSets'],
      '| minutos',d['totalMinutes'],'| sequencia',d['currentStreak'],'| semana',d['sessionsThisWeek'],'/',d['weeklyGoal'])
"
curl -sf "${AUTH[@]}" "$API/api/stats/weekly-volume?weeks=4" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);[print(' ',w['weekStart'],w['volume'],w['sessions']) for w in d]"
curl -sf "${AUTH[@]}" "$API/api/stats/muscle-groups?days=30" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);[print(' ',g['group'],g['volume'],g['sets']) for g in d]"
curl -sf "${AUTH[@]}" "$API/api/stats/exercise/$EX_ID" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);print(d['exerciseName'],'| melhor',d['bestWeight'],'| pontos',len(d['points']))"
curl -sf "${AUTH[@]}" "$API/api/stats/calendar?days=30" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);[print(' ',c['date'],c['sessions'],c['volume']) for c in d]"

step "peso corporal"
curl -sf -X POST "${AUTH[@]}" -H 'Content-Type: application/json' "$API/api/profile/body-weights" \
  -d '{"weightKg":81.9}' | python3 -c "import sys,json;d=json.load(sys.stdin);print('pontos',len(d['points']))"

step "excluir treino duplicado"
DUP_ID=$(curl -sf "${AUTH[@]}" "$API/api/workouts" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print([w['id'] for w in d if 'backup' in w['name']][0])
")
curl -sf -X DELETE "${AUTH[@]}" "$API/api/workouts/$DUP_ID" | head -c 100; echo

step "status do sync com o wger"
curl -sf "${AUTH[@]}" "$API/api/sync/status" | head -c 300; echo

printf "\n\033[1;32mSMOKE TEST OK\033[0m\n"

#!/usr/bin/env python3
"""
Gera a migration Flyway com o catalogo de exercicios do wger.

O objetivo e ter o catalogo completo dentro do banco no primeiro boot,
sem depender de internet. O sync com o wger (POST /api/sync/wger) continua
existindo para atualizar/complementar o catalogo depois.

Uso:
    python3 scripts/generate_exercise_seed.py
    python3 scripts/generate_exercise_seed.py --limit 200   # amostra rapida
"""

from __future__ import annotations

import argparse
import html
import json
import re
import sys
import time
import urllib.request
from pathlib import Path

WGER = "https://wger.de/api/v2"
LANG_EN = 2
LANG_PT = 7
PAGE = 100

OUT = Path(__file__).resolve().parents[1] / "backend/src/main/resources/db/migration/V3__seed_exercises.sql"

# Traducoes curadas para os movimentos mais usados na academia.
PT_NAMES = {
    "bench press": "Supino reto com barra",
    "bench press narrow grip": "Supino reto pegada fechada",
    "bench press wide grip": "Supino reto pegada aberta",
    "bench press dumbbells": "Supino reto com halteres",
    "incline bench press": "Supino inclinado com barra",
    "incline bench press dumbbell": "Supino inclinado com halteres",
    "incline bench press wide grip": "Supino inclinado pegada aberta",
    "decline bench press": "Supino declinado",
    "decline bench press barbell": "Supino declinado com barra",
    "dumbbell bench press": "Supino com halteres",
    "chest press": "Chest press (maquina)",
    "cable crossover": "Crossover na polia",
    "crossovers with rope": "Crossover na polia",
    "butterfly": "Voador (peck deck)",
    "butterfly narrow grip": "Voador pegada fechada",
    "butterfly reverse": "Voador inverso",
    "dumbbell fly": "Crucifixo com halteres",
    "dumbbell flyes": "Crucifixo com halteres",
    "incline dumbbell fly": "Crucifixo inclinado",
    "push ups": "Flexao de bracos",
    "push-up": "Flexao de bracos",
    "push up": "Flexao de bracos",
    "wide push-up": "Flexao pegada aberta",
    "diamond push-up": "Flexao diamante",
    "decline push-up": "Flexao declinada",
    "incline push-up": "Flexao inclinada",
    "dips": "Paralelas (dips)",
    "dips between bench": "Mergulho no banco",
    "pull-ups": "Barra fixa",
    "pull ups": "Barra fixa",
    "pull-up": "Barra fixa",
    "chin-ups": "Barra fixa pegada supinada",
    "chin ups": "Barra fixa pegada supinada",
    "wide-grip pull-up": "Barra fixa pegada aberta",
    "lat pull down": "Puxada na frente (pulley)",
    "lat pulldown": "Puxada na frente (pulley)",
    "lat pull down (band)": "Puxada com elastico",
    "lat pull-down": "Puxada na frente (pulley)",
    "close-grip lat pulldown": "Puxada pegada fechada",
    "bent over rowing": "Remada curvada com barra",
    "bent over rowing barbell": "Remada curvada com barra",
    "bent over rowing reverse": "Remada curvada pegada supinada",
    "dumbbell rowing": "Remada unilateral com halter",
    "one arm dumbbell row": "Remada unilateral com halter",
    "seated cable rows": "Remada baixa sentado",
    "seated row": "Remada baixa sentado",
    "cable seated rows": "Remada baixa sentado",
    "t-bar row": "Remada cavalinho (T-bar)",
    "deadlifts": "Levantamento terra",
    "deadlift": "Levantamento terra",
    "romanian deadlift": "Levantamento terra romeno",
    "sumo deadlift": "Levantamento terra sumo",
    "stiff leg deadlift": "Stiff",
    "shrugs": "Encolhimento de ombros",
    "shrugs dumbbells": "Encolhimento com halteres",
    "shrugs barbell": "Encolhimento com barra",
    "hyperextensions": "Extensao lombar (hiperextensao)",
    "back extension": "Extensao lombar",
    "squats": "Agachamento livre",
    "squat": "Agachamento livre",
    "front squat": "Agachamento frontal",
    "back squat": "Agachamento livre",
    "hack squat": "Agachamento hack",
    "goblet squat": "Agachamento goblet",
    "bulgarian split squat": "Agachamento bulgaro",
    "split squats": "Afundo estatico",
    "leg press": "Leg press",
    "leg extension": "Cadeira extensora",
    "leg extensions": "Cadeira extensora",
    "leg curls": "Mesa flexora",
    "leg curl": "Mesa flexora",
    "lying leg curl": "Mesa flexora",
    "seated leg curl": "Cadeira flexora",
    "lunges": "Afundo",
    "lunge": "Afundo",
    "walking lunges": "Afundo caminhando",
    "lunges with barbell": "Afundo com barra",
    "hip thrust": "Elevacao pelvica",
    "glute bridge": "Ponte de gluteos",
    "calf raises": "Elevacao de panturrilha",
    "standing calf raise": "Panturrilha em pe",
    "seated calf raises": "Panturrilha sentado",
    "donkey calf raises": "Panturrilha burrinho",
    "military press": "Desenvolvimento militar",
    "overhead press": "Desenvolvimento com barra",
    "shoulder press": "Desenvolvimento de ombros",
    "shoulder press dumbbell": "Desenvolvimento com halteres",
    "dumbbell shoulder press": "Desenvolvimento com halteres",
    "arnold shoulder press": "Desenvolvimento Arnold",
    "lateral raises": "Elevacao lateral",
    "side raises": "Elevacao lateral",
    "lateral raises with cable": "Elevacao lateral na polia",
    "front raises": "Elevacao frontal",
    "front raises with dumbbell": "Elevacao frontal com halteres",
    "reverse flyes": "Crucifixo inverso",
    "bent over lateral raises": "Elevacao lateral curvado",
    "face pull": "Face pull",
    "upright row": "Remada alta",
    "biceps curls with barbell": "Rosca direta com barra",
    "biceps curl": "Rosca direta",
    "biceps curls with dumbbell": "Rosca direta com halteres",
    "biceps curls with sz-bar": "Rosca direta com barra W",
    "biceps curls with cable": "Rosca na polia",
    "hammer curl": "Rosca martelo",
    "hammer curls": "Rosca martelo",
    "concentration curls": "Rosca concentrada",
    "preacher curl": "Rosca scott",
    "incline curl": "Rosca inclinada",
    "triceps extension": "Extensao de triceps",
    "triceps extension with cable": "Triceps na polia",
    "french press": "Triceps testa",
    "french press sz-bar": "Triceps testa com barra W",
    "skull crusher": "Triceps testa",
    "close-grip bench press": "Supino pegada fechada",
    "kickback": "Triceps coice",
    "triceps kickback": "Triceps coice",
    "overhead triceps extension": "Triceps frances",
    "crunches": "Abdominal crunch",
    "crunch": "Abdominal crunch",
    "sit-ups": "Abdominal supra",
    "leg raises": "Elevacao de pernas",
    "hanging leg raise": "Elevacao de pernas suspenso",
    "plank": "Prancha",
    "planks": "Prancha",
    "side plank": "Prancha lateral",
    "russian twist": "Russian twist",
    "mountain climbers": "Escalador",
    "bicycle crunch": "Abdominal bicicleta",
    "ab wheel rollout": "Rolo abdominal",
    "cable crunch": "Abdominal na polia",
    "burpees": "Burpee",
    "jumping jacks": "Polichinelo",
    "running": "Corrida",
    "cycling": "Bicicleta",
    "rowing machine": "Remo ergometro",
    "jump rope": "Pular corda",
    "farmer's walk": "Caminhada do fazendeiro",
    "clean and jerk": "Arremesso (clean and jerk)",
    "power clean": "Power clean",
    "kettlebell swing": "Kettlebell swing",
    "kettlebell swings": "Kettlebell swing",
    "good mornings": "Good morning",
    "pullover": "Pullover",
    "pull over": "Pullover",
}

TAG_RE = re.compile(r"<[^>]+>")
WS_RE = re.compile(r"[ \t]+")


def fetch(url: str, attempts: int = 4) -> dict:
    last = None
    for i in range(attempts):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "meu-treino-seed/1.0"})
            with urllib.request.urlopen(req, timeout=60) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except Exception as exc:  # noqa: BLE001
            last = exc
            time.sleep(2 * (i + 1))
    raise RuntimeError(f"falha ao buscar {url}: {last}")


def clean_html(raw: str | None) -> str | None:
    if not raw:
        return None
    text = raw.replace("</p>", "\n").replace("<br>", "\n").replace("<br/>", "\n").replace("<br />", "\n")
    text = text.replace("</li>", "\n").replace("<li>", "- ")
    text = TAG_RE.sub("", text)
    text = html.unescape(text)
    text = WS_RE.sub(" ", text)
    lines = [line.strip() for line in text.split("\n")]
    text = "\n".join(line for line in lines if line)
    return text.strip() or None


def q(value) -> str:
    if value is None:
        return "NULL"
    if isinstance(value, bool):
        return "TRUE" if value else "FALSE"
    if isinstance(value, (int, float)):
        return str(value)
    return "'" + str(value).replace("'", "''") + "'"


def pick_translation(translations: list[dict], language: int) -> dict | None:
    for t in translations:
        if t.get("language") == language and (t.get("name") or "").strip():
            return t
    return None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=0, help="limite de exercicios (0 = todos)")
    args = parser.parse_args()

    print("Buscando catalogo no wger...", file=sys.stderr)
    exercises: list[dict] = []
    url = f"{WGER}/exerciseinfo/?format=json&limit={PAGE}&offset=0"
    while url:
        data = fetch(url)
        exercises.extend(data["results"])
        print(f"  {len(exercises)}/{data['count']}", file=sys.stderr)
        if args.limit and len(exercises) >= args.limit:
            exercises = exercises[: args.limit]
            break
        url = data.get("next")

    rows_ex: list[str] = []
    rows_muscle: list[str] = []
    rows_equip: list[str] = []
    rows_image: list[str] = []
    rows_video: list[str] = []

    next_id = 1
    seen_names: set[str] = set()

    for ex in exercises:
        translations = ex.get("translations") or []
        en = pick_translation(translations, LANG_EN)
        pt = pick_translation(translations, LANG_PT)
        if not en and not pt:
            continue

        name = (en or pt)["name"].strip()
        key = name.lower()
        if key in seen_names:
            continue
        seen_names.add(key)

        name_pt = None
        if pt:
            name_pt = pt["name"].strip()
        if key in PT_NAMES:
            name_pt = PT_NAMES[key]

        description = clean_html((en or pt).get("description"))
        if not description and pt:
            description = clean_html(pt.get("description"))
        if description and len(description) > 4000:
            description = description[:4000]

        category = ex.get("category") or {}
        category_id = category.get("id")

        eid = next_id
        next_id += 1

        rows_ex.append(
            "({}, {}, {}, {}, {}, {}, {}, 'WGER')".format(
                eid,
                q(ex["id"]),
                q(ex.get("uuid")),
                q(name[:255]),
                q(name_pt[:255] if name_pt else None),
                q(description),
                q(category_id),
            )
        )

        for m in ex.get("muscles") or []:
            rows_muscle.append(f"({eid}, {m['id']}, TRUE)")
        for m in ex.get("muscles_secondary") or []:
            rows_muscle.append(f"({eid}, {m['id']}, FALSE)")
        for e in ex.get("equipment") or []:
            rows_equip.append(f"({eid}, {e['id']})")

        img_urls = set()
        for img in ex.get("images") or []:
            u = img.get("image")
            if u and u not in img_urls:
                img_urls.add(u)
                rows_image.append(f"({eid}, {q(u)}, {q(bool(img.get('is_main')))})")

        vid_urls = set()
        for vid in ex.get("videos") or []:
            u = vid.get("video")
            if u and u not in vid_urls:
                vid_urls.add(u)
                rows_video.append(f"({eid}, {q(u)})")

    def block(table: str, columns: str, rows: list[str], conflict: str = "") -> str:
        if not rows:
            return ""
        parts = []
        for i in range(0, len(rows), 500):
            chunk = rows[i : i + 500]
            parts.append(
                f"INSERT INTO {table} ({columns}) VALUES\n" + ",\n".join(chunk) + f"\n{conflict};\n"
            )
        return "\n".join(parts)

    sql = [
        "-- =====================================================================",
        "-- Catalogo de exercicios (fonte: wger.de - CC-BY-SA 4.0)",
        f"-- Gerado por scripts/generate_exercise_seed.py - {len(rows_ex)} exercicios",
        "-- =====================================================================",
        "",
        block(
            "exercises",
            "id, wger_id, uuid, name, name_pt, description, category_id, source",
            rows_ex,
            "ON CONFLICT (wger_id) DO NOTHING",
        ),
        block("exercise_muscles", "exercise_id, muscle_id, is_primary", rows_muscle, "ON CONFLICT DO NOTHING"),
        block("exercise_equipment", "exercise_id, equipment_id", rows_equip, "ON CONFLICT DO NOTHING"),
        block("exercise_images", "exercise_id, url, is_main", rows_image, "ON CONFLICT DO NOTHING"),
        block("exercise_videos", "exercise_id, url", rows_video, "ON CONFLICT DO NOTHING"),
        "SELECT setval('exercises_id_seq', (SELECT COALESCE(MAX(id), 1) FROM exercises));",
        "",
    ]

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text("\n".join(sql), encoding="utf-8")
    print(
        f"OK -> {OUT} ({len(rows_ex)} exercicios, {len(rows_image)} imagens, {len(rows_video)} videos)",
        file=sys.stderr,
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

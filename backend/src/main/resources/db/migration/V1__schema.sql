-- =====================================================================
-- Meu Treino - schema inicial
-- =====================================================================

-- ------------------------------ usuarios -----------------------------
CREATE TABLE users (
    id            BIGSERIAL PRIMARY KEY,
    name          VARCHAR(120) NOT NULL,
    email         VARCHAR(180) NOT NULL UNIQUE,
    password_hash VARCHAR(120) NOT NULL,
    created_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE TABLE profiles (
    user_id         BIGINT PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    weight_kg       NUMERIC(6, 2),
    height_cm       INTEGER,
    birth_date      DATE,
    gender          VARCHAR(20),
    goal            VARCHAR(40),
    experience      VARCHAR(40),
    available_days  INTEGER,
    session_minutes INTEGER,
    weekly_goal     INTEGER,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE body_weights (
    id          BIGSERIAL PRIMARY KEY,
    user_id     BIGINT        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    weight_kg   NUMERIC(6, 2) NOT NULL,
    measured_at DATE          NOT NULL,
    CONSTRAINT uk_body_weights_day UNIQUE (user_id, measured_at)
);

-- --------------------------- catalogo base ---------------------------
CREATE TABLE muscles (
    id                   INTEGER PRIMARY KEY,
    name                 VARCHAR(120) NOT NULL,
    name_pt              VARCHAR(120),
    name_en              VARCHAR(120),
    is_front             BOOLEAN      NOT NULL DEFAULT TRUE,
    image_url_main       TEXT,
    image_url_secondary  TEXT
);

CREATE TABLE equipment (
    id      INTEGER PRIMARY KEY,
    name    VARCHAR(120) NOT NULL,
    name_pt VARCHAR(120)
);

CREATE TABLE exercise_categories (
    id      INTEGER PRIMARY KEY,
    name    VARCHAR(120) NOT NULL,
    name_pt VARCHAR(120)
);

CREATE TABLE exercises (
    id          BIGSERIAL PRIMARY KEY,
    wger_id     INTEGER UNIQUE,
    uuid        VARCHAR(64),
    name        VARCHAR(255) NOT NULL,
    name_pt     VARCHAR(255),
    description TEXT,
    category_id INTEGER REFERENCES exercise_categories (id) ON DELETE SET NULL,
    source      VARCHAR(20)  NOT NULL DEFAULT 'WGER',
    created_at  TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_exercises_name ON exercises (LOWER(name));
CREATE INDEX idx_exercises_name_pt ON exercises (LOWER(name_pt));
CREATE INDEX idx_exercises_category ON exercises (category_id);

CREATE TABLE exercise_muscles (
    exercise_id  BIGINT  NOT NULL REFERENCES exercises (id) ON DELETE CASCADE,
    muscle_id    INTEGER NOT NULL REFERENCES muscles (id) ON DELETE CASCADE,
    is_primary   BOOLEAN NOT NULL DEFAULT TRUE,
    PRIMARY KEY (exercise_id, muscle_id, is_primary)
);

CREATE INDEX idx_exercise_muscles_muscle ON exercise_muscles (muscle_id);

CREATE TABLE exercise_equipment (
    exercise_id  BIGINT  NOT NULL REFERENCES exercises (id) ON DELETE CASCADE,
    equipment_id INTEGER NOT NULL REFERENCES equipment (id) ON DELETE CASCADE,
    PRIMARY KEY (exercise_id, equipment_id)
);

CREATE INDEX idx_exercise_equipment_equipment ON exercise_equipment (equipment_id);

CREATE TABLE exercise_images (
    id          BIGSERIAL PRIMARY KEY,
    exercise_id BIGINT  NOT NULL REFERENCES exercises (id) ON DELETE CASCADE,
    url         TEXT    NOT NULL,
    is_main     BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uk_exercise_images UNIQUE (exercise_id, url)
);

CREATE TABLE exercise_videos (
    id          BIGSERIAL PRIMARY KEY,
    exercise_id BIGINT NOT NULL REFERENCES exercises (id) ON DELETE CASCADE,
    url         TEXT   NOT NULL,
    CONSTRAINT uk_exercise_videos UNIQUE (exercise_id, url)
);

-- ------------------------------ treinos ------------------------------
CREATE TABLE workouts (
    id         BIGSERIAL PRIMARY KEY,
    user_id    BIGINT       NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    name       VARCHAR(140) NOT NULL,
    notes      TEXT,
    split_type VARCHAR(30)  NOT NULL DEFAULT 'CUSTOM',
    color      VARCHAR(20),
    archived   BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_workouts_user ON workouts (user_id);

CREATE TABLE workout_days (
    id          BIGSERIAL PRIMARY KEY,
    workout_id  BIGINT       NOT NULL REFERENCES workouts (id) ON DELETE CASCADE,
    label       VARCHAR(12)  NOT NULL,
    name        VARCHAR(140) NOT NULL,
    order_index INTEGER      NOT NULL DEFAULT 0
);

CREATE INDEX idx_workout_days_workout ON workout_days (workout_id);

CREATE TABLE workout_exercises (
    id              BIGSERIAL PRIMARY KEY,
    workout_day_id  BIGINT      NOT NULL REFERENCES workout_days (id) ON DELETE CASCADE,
    exercise_id     BIGINT      NOT NULL REFERENCES exercises (id) ON DELETE CASCADE,
    order_index     INTEGER     NOT NULL DEFAULT 0,
    target_sets     INTEGER     NOT NULL DEFAULT 3,
    target_reps     VARCHAR(20) NOT NULL DEFAULT '10',
    target_weight   NUMERIC(7, 2),
    rest_seconds    INTEGER     NOT NULL DEFAULT 90,
    notes           TEXT
);

CREATE INDEX idx_workout_exercises_day ON workout_exercises (workout_day_id);

-- ------------------------- sessoes de treino -------------------------
CREATE TABLE sessions (
    id               BIGSERIAL PRIMARY KEY,
    user_id          BIGINT      NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    workout_id       BIGINT      REFERENCES workouts (id) ON DELETE SET NULL,
    workout_day_id   BIGINT      REFERENCES workout_days (id) ON DELETE SET NULL,
    workout_name     VARCHAR(140),
    day_label        VARCHAR(12),
    day_name         VARCHAR(140),
    status           VARCHAR(20) NOT NULL DEFAULT 'IN_PROGRESS',
    started_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at      TIMESTAMPTZ,
    duration_seconds INTEGER,
    total_volume     NUMERIC(12, 2) NOT NULL DEFAULT 0,
    total_sets       INTEGER     NOT NULL DEFAULT 0,
    notes            TEXT
);

CREATE INDEX idx_sessions_user_started ON sessions (user_id, started_at DESC);
CREATE INDEX idx_sessions_status ON sessions (user_id, status);

CREATE TABLE session_exercises (
    id                   BIGSERIAL PRIMARY KEY,
    session_id           BIGINT  NOT NULL REFERENCES sessions (id) ON DELETE CASCADE,
    workout_exercise_id  BIGINT  REFERENCES workout_exercises (id) ON DELETE SET NULL,
    exercise_id          BIGINT  NOT NULL REFERENCES exercises (id) ON DELETE CASCADE,
    original_exercise_id BIGINT  REFERENCES exercises (id) ON DELETE SET NULL,
    order_index          INTEGER NOT NULL DEFAULT 0,
    rest_seconds         INTEGER NOT NULL DEFAULT 90,
    notes                TEXT
);

CREATE INDEX idx_session_exercises_session ON session_exercises (session_id);
CREATE INDEX idx_session_exercises_exercise ON session_exercises (exercise_id);

CREATE TABLE session_sets (
    id                  BIGSERIAL PRIMARY KEY,
    session_exercise_id BIGINT      NOT NULL REFERENCES session_exercises (id) ON DELETE CASCADE,
    set_number          INTEGER     NOT NULL,
    target_reps         VARCHAR(20),
    reps                INTEGER,
    weight              NUMERIC(7, 2),
    completed           BOOLEAN     NOT NULL DEFAULT FALSE,
    completed_at        TIMESTAMPTZ,
    rpe                 INTEGER
);

CREATE INDEX idx_session_sets_exercise ON session_sets (session_exercise_id);

-- ------------------------ controle de sync ---------------------------
CREATE TABLE sync_log (
    id            BIGSERIAL PRIMARY KEY,
    source        VARCHAR(30) NOT NULL,
    status        VARCHAR(20) NOT NULL,
    exercises     INTEGER     NOT NULL DEFAULT 0,
    message       TEXT,
    started_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    finished_at   TIMESTAMPTZ
);

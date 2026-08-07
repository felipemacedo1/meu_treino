-- Cache local de imagens/videos vindos do wger, para o app funcionar offline.
CREATE TABLE media_cache (
    id           BIGSERIAL PRIMARY KEY,
    url_hash     VARCHAR(64)  NOT NULL UNIQUE,
    url          TEXT         NOT NULL,
    content_type VARCHAR(120),
    size_bytes   INTEGER      NOT NULL DEFAULT 0,
    data         BYTEA        NOT NULL,
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now()
);

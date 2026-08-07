-- Ordenação padrão do catálogo: exercícios traduzidos e ilustrados primeiro.
-- quality = 2 (tem nome em PT) + 1 (tem imagem)
ALTER TABLE exercises ADD COLUMN quality SMALLINT NOT NULL DEFAULT 0;

UPDATE exercises e
SET quality = (CASE WHEN e.name_pt IS NOT NULL AND e.name_pt <> '' THEN 2 ELSE 0 END)
            + (CASE WHEN EXISTS (SELECT 1 FROM exercise_images i WHERE i.exercise_id = e.id)
                    THEN 1 ELSE 0 END);

CREATE INDEX idx_exercises_quality ON exercises (quality DESC, name ASC);

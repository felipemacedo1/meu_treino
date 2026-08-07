-- =====================================================================
-- Catalogo base (ids compativeis com o wger para permitir upsert no sync)
-- =====================================================================

INSERT INTO muscles (id, name, name_pt, name_en, is_front, image_url_main, image_url_secondary) VALUES
 (1,  'Biceps brachii',               'Biceps',            'Biceps',     TRUE,  'https://wger.de/static/images/muscles/main/muscle-1.svg',  'https://wger.de/static/images/muscles/secondary/muscle-1.svg'),
 (2,  'Anterior deltoid',             'Ombros',            'Shoulders',  TRUE,  'https://wger.de/static/images/muscles/main/muscle-2.svg',  'https://wger.de/static/images/muscles/secondary/muscle-2.svg'),
 (3,  'Serratus anterior',            'Serratil anterior', '',           TRUE,  'https://wger.de/static/images/muscles/main/muscle-3.svg',  'https://wger.de/static/images/muscles/secondary/muscle-3.svg'),
 (4,  'Pectoralis major',             'Peitoral',          'Chest',      TRUE,  'https://wger.de/static/images/muscles/main/muscle-4.svg',  'https://wger.de/static/images/muscles/secondary/muscle-4.svg'),
 (5,  'Triceps brachii',              'Triceps',           'Triceps',    FALSE, 'https://wger.de/static/images/muscles/main/muscle-5.svg',  'https://wger.de/static/images/muscles/secondary/muscle-5.svg'),
 (6,  'Rectus abdominis',             'Abdomen',           'Abs',        TRUE,  'https://wger.de/static/images/muscles/main/muscle-6.svg',  'https://wger.de/static/images/muscles/secondary/muscle-6.svg'),
 (7,  'Gastrocnemius',                'Panturrilha',       'Calves',     FALSE, 'https://wger.de/static/images/muscles/main/muscle-7.svg',  'https://wger.de/static/images/muscles/secondary/muscle-7.svg'),
 (8,  'Gluteus maximus',              'Gluteos',           'Glutes',     FALSE, 'https://wger.de/static/images/muscles/main/muscle-8.svg',  'https://wger.de/static/images/muscles/secondary/muscle-8.svg'),
 (9,  'Trapezius',                    'Trapezio',          '',           FALSE, 'https://wger.de/static/images/muscles/main/muscle-9.svg',  'https://wger.de/static/images/muscles/secondary/muscle-9.svg'),
 (10, 'Quadriceps femoris',           'Quadriceps',        'Quads',      TRUE,  'https://wger.de/static/images/muscles/main/muscle-10.svg', 'https://wger.de/static/images/muscles/secondary/muscle-10.svg'),
 (11, 'Biceps femoris',               'Posterior de coxa', 'Hamstrings', FALSE, 'https://wger.de/static/images/muscles/main/muscle-11.svg', 'https://wger.de/static/images/muscles/secondary/muscle-11.svg'),
 (12, 'Latissimus dorsi',             'Dorsais',           'Lats',       FALSE, 'https://wger.de/static/images/muscles/main/muscle-12.svg', 'https://wger.de/static/images/muscles/secondary/muscle-12.svg'),
 (13, 'Brachialis',                   'Braquial',          '',           TRUE,  'https://wger.de/static/images/muscles/main/muscle-13.svg', 'https://wger.de/static/images/muscles/secondary/muscle-13.svg'),
 (14, 'Obliquus externus abdominis',  'Obliquos',          '',           TRUE,  'https://wger.de/static/images/muscles/main/muscle-14.svg', 'https://wger.de/static/images/muscles/secondary/muscle-14.svg'),
 (15, 'Soleus',                       'Soleo',             '',           FALSE, 'https://wger.de/static/images/muscles/main/muscle-15.svg', 'https://wger.de/static/images/muscles/secondary/muscle-15.svg')
ON CONFLICT (id) DO NOTHING;

INSERT INTO equipment (id, name, name_pt) VALUES
 (1,  'Barbell',                   'Barra'),
 (2,  'SZ-Bar',                    'Barra W'),
 (3,  'Dumbbell',                  'Halteres'),
 (4,  'Gym mat',                   'Colchonete'),
 (5,  'Swiss Ball',                'Bola suica'),
 (6,  'Pull-up bar',               'Barra fixa'),
 (7,  'none (bodyweight exercise)','Peso corporal'),
 (8,  'Bench',                     'Banco'),
 (9,  'Incline bench',             'Banco inclinado'),
 (10, 'Kettlebell',                'Kettlebell'),
 (11, 'Resistance band',           'Elastico'),
 (12, 'Cable machine',             'Maquina / cabo')
ON CONFLICT (id) DO NOTHING;

INSERT INTO exercise_categories (id, name, name_pt) VALUES
 (8,  'Arms',      'Bracos'),
 (9,  'Legs',      'Pernas'),
 (10, 'Abs',       'Abdomen'),
 (11, 'Chest',     'Peito'),
 (12, 'Back',      'Costas'),
 (13, 'Shoulders', 'Ombros'),
 (14, 'Calves',    'Panturrilhas'),
 (15, 'Cardio',    'Cardio')
ON CONFLICT (id) DO NOTHING;

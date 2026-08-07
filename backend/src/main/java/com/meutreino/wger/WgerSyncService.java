package com.meutreino.wger;

import java.time.Instant;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.atomic.AtomicBoolean;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import com.meutreino.config.AppProperties;
import com.meutreino.exercise.CatalogService;
import com.meutreino.exercise.Equipment;
import com.meutreino.exercise.EquipmentRepository;
import com.meutreino.exercise.Exercise;
import com.meutreino.exercise.ExerciseCategory;
import com.meutreino.exercise.ExerciseCategoryRepository;
import com.meutreino.exercise.ExerciseMedia;
import com.meutreino.exercise.ExerciseMuscleRef;
import com.meutreino.exercise.ExerciseRepository;
import com.meutreino.exercise.Muscle;
import com.meutreino.exercise.MuscleRepository;
import com.meutreino.media.MediaService;
import com.meutreino.wger.WgerDtos.WgerExercise;
import com.meutreino.wger.WgerDtos.WgerTranslation;

/**
 * Sincroniza o catalogo do wger para o banco local.
 *
 * <p>O catalogo ja vem populado por migration (V3), esse sync serve para
 * atualizar/complementar. Depois de rodar, o app funciona sem internet.
 */
@Service
public class WgerSyncService {

    private static final Logger log = LoggerFactory.getLogger(WgerSyncService.class);
    private static final int LANG_EN = 2;
    private static final int LANG_PT = 7;

    private final WgerClient client;
    private final ExerciseRepository exerciseRepository;
    private final MuscleRepository muscleRepository;
    private final EquipmentRepository equipmentRepository;
    private final ExerciseCategoryRepository categoryRepository;
    private final SyncLogRepository syncLogRepository;
    private final CatalogService catalogService;
    private final MediaService mediaService;
    private final AppProperties properties;
    private final TransactionTemplate transactionTemplate;

    private final AtomicBoolean running = new AtomicBoolean(false);

    public WgerSyncService(WgerClient client,
                          ExerciseRepository exerciseRepository,
                          MuscleRepository muscleRepository,
                          EquipmentRepository equipmentRepository,
                          ExerciseCategoryRepository categoryRepository,
                          SyncLogRepository syncLogRepository,
                          CatalogService catalogService,
                          MediaService mediaService,
                          AppProperties properties,
                          PlatformTransactionManager transactionManager) {
        this.client = client;
        this.exerciseRepository = exerciseRepository;
        this.muscleRepository = muscleRepository;
        this.equipmentRepository = equipmentRepository;
        this.categoryRepository = categoryRepository;
        this.syncLogRepository = syncLogRepository;
        this.catalogService = catalogService;
        this.mediaService = mediaService;
        this.properties = properties;
        this.transactionTemplate = new TransactionTemplate(transactionManager);
        this.transactionTemplate.setTimeout(600);
    }

    public boolean isRunning() {
        return running.get();
    }

    public Optional<SyncLog> lastSync() {
        return syncLogRepository.findFirstByOrderByStartedAtDesc();
    }

    public List<SyncLog> history() {
        return syncLogRepository.findTop10ByOrderByStartedAtDesc();
    }

    @Async
    public void syncAsync() {
        sync();
    }

    public SyncLog sync() {
        if (!running.compareAndSet(false, true)) {
            log.info("Sync do wger ja esta em andamento");
            return lastSync().orElse(null);
        }
        SyncLog logEntry = new SyncLog();
        logEntry.setSource("WGER");
        logEntry.setStatus("RUNNING");
        syncLogRepository.save(logEntry);
        try {
            Integer count = transactionTemplate.execute(status -> doSync());
            logEntry.setStatus("SUCCESS");
            logEntry.setExercises(count == null ? 0 : count);
            logEntry.setMessage("Catalogo sincronizado com sucesso");
        } catch (Exception ex) {
            log.error("Falha no sync do wger", ex);
            logEntry.setStatus("ERROR");
            logEntry.setMessage(ex.getMessage());
        } finally {
            logEntry.setFinishedAt(Instant.now());
            syncLogRepository.save(logEntry);
            running.set(false);
        }
        return logEntry;
    }

    private int doSync() {        syncCatalog();

        List<WgerExercise> remote = client.exercises();
        log.info("wger: processando {} exercicios", remote.size());

        Map<Integer, ExerciseCategory> categories = new HashMap<>();
        categoryRepository.findAll().forEach(c -> categories.put(c.getId(), c));
        Map<Integer, Equipment> equipments = new HashMap<>();
        equipmentRepository.findAll().forEach(e -> equipments.put(e.getId(), e));

        int saved = 0;
        for (WgerExercise remoteExercise : remote) {
            WgerTranslation en = translation(remoteExercise, LANG_EN);
            WgerTranslation pt = translation(remoteExercise, LANG_PT);
            if (en == null && pt == null) {
                continue;
            }
            WgerTranslation base = en != null ? en : pt;

            Exercise exercise = exerciseRepository.findByWgerId(remoteExercise.id()).orElseGet(Exercise::new);
            exercise.setWgerId(remoteExercise.id());
            exercise.setUuid(remoteExercise.uuid());
            exercise.setName(trim(base.name(), 255));
            if (pt != null) {
                exercise.setNamePt(trim(pt.name(), 255));
            }
            exercise.setDescription(trim(Html.toPlainText(base.description()), 4000));
            exercise.setSource("WGER");
            if (remoteExercise.category() != null) {
                exercise.setCategory(categories.get(remoteExercise.category().id()));
            }

            var muscles = new LinkedHashSet<ExerciseMuscleRef>();
            if (remoteExercise.muscles() != null) {
                remoteExercise.muscles().forEach(m -> muscles.add(new ExerciseMuscleRef(m.id(), true)));
            }
            if (remoteExercise.musclesSecondary() != null) {
                remoteExercise.musclesSecondary().forEach(m -> muscles.add(new ExerciseMuscleRef(m.id(), false)));
            }
            exercise.getMuscles().clear();
            exercise.getMuscles().addAll(muscles);

            exercise.getEquipment().clear();
            if (remoteExercise.equipment() != null) {
                remoteExercise.equipment().stream()
                        .map(e -> equipments.get(e.id()))
                        .filter(java.util.Objects::nonNull)
                        .forEach(exercise.getEquipment()::add);
            }

            var images = new LinkedHashSet<ExerciseMedia>();
            if (remoteExercise.images() != null) {
                remoteExercise.images().stream()
                        .filter(i -> i.image() != null && !i.image().isBlank())
                        .forEach(i -> {
                            images.add(new ExerciseMedia(i.image(), Boolean.TRUE.equals(i.main())));
                            mediaService.register(i.image());
                        });
            }
            exercise.getImages().clear();
            exercise.getImages().addAll(images);

            var videos = new LinkedHashSet<String>();
            if (remoteExercise.videos() != null) {
                remoteExercise.videos().stream()
                        .filter(v -> v.video() != null && !v.video().isBlank())
                        .forEach(v -> {
                            videos.add(v.video());
                            mediaService.register(v.video());
                        });
            }
            exercise.getVideos().clear();
            exercise.getVideos().addAll(videos);

            short quality = 0;
            if (exercise.getNamePt() != null && !exercise.getNamePt().isBlank()) {
                quality += 2;
            }
            if (!images.isEmpty()) {
                quality += 1;
            }
            exercise.setQuality(quality);

            exerciseRepository.save(exercise);
            saved++;
        }

        catalogService.reload();
        log.info("wger: {} exercicios sincronizados", saved);
        return saved;
    }

    private void syncCatalog() {
        client.muscles().forEach(remote -> {
            Muscle muscle = muscleRepository.findById(remote.id()).orElseGet(Muscle::new);
            muscle.setId(remote.id());
            muscle.setName(remote.name());
            muscle.setNameEn(remote.nameEn());
            muscle.setFront(Boolean.TRUE.equals(remote.front()));
            muscle.setImageUrlMain(remote.imageUrlMain());
            muscle.setImageUrlSecondary(remote.imageUrlSecondary());
            muscleRepository.save(muscle);
        });
        client.equipment().forEach(remote -> {
            Equipment equipment = equipmentRepository.findById(remote.id()).orElseGet(Equipment::new);
            equipment.setId(remote.id());
            equipment.setName(remote.name());
            equipmentRepository.save(equipment);
        });
        client.categories().forEach(remote -> {
            ExerciseCategory category = categoryRepository.findById(remote.id()).orElseGet(ExerciseCategory::new);
            category.setId(remote.id());
            category.setName(remote.name());
            categoryRepository.save(category);
        });
    }

    private WgerTranslation translation(WgerExercise exercise, int language) {
        if (exercise.translations() == null) {
            return null;
        }
        return exercise.translations().stream()
                .filter(t -> language == (t.language() == null ? -1 : t.language()))
                .filter(t -> t.name() != null && !t.name().isBlank())
                .findFirst()
                .orElse(null);
    }

    private String trim(String value, int max) {
        if (value == null) {
            return null;
        }
        return value.length() <= max ? value : value.substring(0, max);
    }
}

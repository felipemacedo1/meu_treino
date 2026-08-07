package com.meutreino.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

import com.meutreino.exercise.CatalogService;
import com.meutreino.exercise.ExerciseRepository;
import com.meutreino.media.MediaService;
import com.meutreino.wger.WgerSyncService;

/**
 * Aquece os caches e garante que existe catalogo de exercicios.
 * O catalogo padrao vem por migration; o sync com o wger so roda se o banco
 * estiver vazio (ou quando chamado manualmente em /api/sync/wger).
 */
@Component
public class StartupInitializer implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(StartupInitializer.class);

    private final CatalogService catalogService;
    private final MediaService mediaService;
    private final ExerciseRepository exerciseRepository;
    private final WgerSyncService syncService;
    private final AppProperties properties;

    public StartupInitializer(CatalogService catalogService,
                              MediaService mediaService,
                              ExerciseRepository exerciseRepository,
                              WgerSyncService syncService,
                              AppProperties properties) {
        this.catalogService = catalogService;
        this.mediaService = mediaService;
        this.exerciseRepository = exerciseRepository;
        this.syncService = syncService;
        this.properties = properties;
    }

    @Override
    public void run(ApplicationArguments args) {
        catalogService.reload();
        mediaService.reloadRegistry();

        long total = exerciseRepository.count();
        log.info("Catalogo local com {} exercicios", total);
        if (total == 0 && properties.wger().syncOnStartup()) {
            log.info("Catalogo vazio: iniciando sync com o wger em background");
            syncService.syncAsync();
        }
    }
}

package com.meutreino.wger;

import java.util.List;
import java.util.Map;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/sync")
@Tag(name = "Sincronizacao wger")
public class SyncController {

    private final WgerSyncService syncService;

    public SyncController(WgerSyncService syncService) {
        this.syncService = syncService;
    }

    @PostMapping("/wger")
    @Operation(summary = "Sincroniza o catalogo de exercicios do wger para o banco local")
    public Map<String, Object> sync(@RequestParam(defaultValue = "true") boolean async) {
        if (syncService.isRunning()) {
            return Map.of("status", "RUNNING", "message", "Sincronizacao ja em andamento");
        }
        if (async) {
            syncService.syncAsync();
            return Map.of("status", "STARTED", "message", "Sincronizacao iniciada em background");
        }
        SyncLog result = syncService.sync();
        return Map.of(
                "status", result.getStatus(),
                "exercises", result.getExercises(),
                "message", result.getMessage() == null ? "" : result.getMessage());
    }

    @GetMapping("/status")
    public Map<String, Object> status() {
        return syncService.lastSync()
                .map(log -> Map.<String, Object>of(
                        "running", syncService.isRunning(),
                        "status", log.getStatus(),
                        "exercises", log.getExercises(),
                        "startedAt", log.getStartedAt().toString(),
                        "finishedAt", log.getFinishedAt() == null ? "" : log.getFinishedAt().toString(),
                        "message", log.getMessage() == null ? "" : log.getMessage()))
                .orElseGet(() -> Map.of("running", syncService.isRunning(), "status", "NEVER"));
    }

    @GetMapping("/history")
    public List<SyncLog> history() {
        return syncService.history();
    }
}

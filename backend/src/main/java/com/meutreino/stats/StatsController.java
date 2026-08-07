package com.meutreino.stats;

import java.util.List;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.meutreino.security.AuthPrincipal;
import com.meutreino.stats.dto.StatsDtos.CalendarDayDto;
import com.meutreino.stats.dto.StatsDtos.ExerciseProgressionDto;
import com.meutreino.stats.dto.StatsDtos.MuscleGroupVolumeDto;
import com.meutreino.stats.dto.StatsDtos.OverviewDto;
import com.meutreino.stats.dto.StatsDtos.WeeklyVolumeDto;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/stats")
@Tag(name = "Estatisticas")
public class StatsController {

    private final StatsService service;

    public StatsController(StatsService service) {
        this.service = service;
    }

    @GetMapping("/overview")
    @Operation(summary = "Resumo geral: treinos, volume, sequencia de dias, peso movimentado")
    public OverviewDto overview(@AuthenticationPrincipal AuthPrincipal principal) {
        return service.overview(principal.userId());
    }

    @GetMapping("/weekly-volume")
    public List<WeeklyVolumeDto> weeklyVolume(@AuthenticationPrincipal AuthPrincipal principal,
                                             @RequestParam(defaultValue = "12") int weeks) {
        return service.weeklyVolume(principal.userId(), weeks);
    }

    @GetMapping("/muscle-groups")
    public List<MuscleGroupVolumeDto> muscleGroups(@AuthenticationPrincipal AuthPrincipal principal,
                                                  @RequestParam(defaultValue = "30") int days) {
        return service.muscleGroups(principal.userId(), days);
    }

    @GetMapping("/exercise/{exerciseId}")
    @Operation(summary = "Evolucao de carga e volume de um exercicio")
    public ExerciseProgressionDto exercise(@AuthenticationPrincipal AuthPrincipal principal,
                                          @PathVariable Long exerciseId) {
        return service.exerciseProgression(principal.userId(), exerciseId);
    }

    @GetMapping("/calendar")
    public List<CalendarDayDto> calendar(@AuthenticationPrincipal AuthPrincipal principal,
                                        @RequestParam(defaultValue = "120") int days) {
        return service.calendar(principal.userId(), days);
    }
}

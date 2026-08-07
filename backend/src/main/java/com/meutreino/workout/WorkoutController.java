package com.meutreino.workout;

import java.util.List;
import java.util.Map;

import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.meutreino.security.AuthPrincipal;
import com.meutreino.workout.dto.WorkoutDtos.SplitOptionDto;
import com.meutreino.workout.dto.WorkoutDtos.TemplateRequest;
import com.meutreino.workout.dto.WorkoutDtos.WorkoutDto;
import com.meutreino.workout.dto.WorkoutDtos.WorkoutRequest;
import com.meutreino.workout.dto.WorkoutDtos.WorkoutSummaryDto;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/workouts")
@Tag(name = "Treinos")
public class WorkoutController {

    private final WorkoutService service;

    public WorkoutController(WorkoutService service) {
        this.service = service;
    }

    @GetMapping
    public List<WorkoutSummaryDto> list(@AuthenticationPrincipal AuthPrincipal principal,
                                       @RequestParam(defaultValue = "false") boolean includeArchived) {
        return service.list(principal.userId(), includeArchived);
    }

    @GetMapping("/splits")
    @Operation(summary = "Divisoes prontas (ABC, ABCD, ABCDE, PPL, Upper/Lower, Full Body)")
    public List<SplitOptionDto> splits() {
        return service.splitOptions();
    }

    @GetMapping("/{id}")
    public WorkoutDto get(@AuthenticationPrincipal AuthPrincipal principal, @PathVariable Long id) {
        return service.get(principal.userId(), id);
    }

    @PostMapping
    public WorkoutDto create(@AuthenticationPrincipal AuthPrincipal principal,
                             @Valid @RequestBody WorkoutRequest request) {
        return service.create(principal.userId(), request);
    }

    @PostMapping("/from-template")
    @Operation(summary = "Cria um treino completo a partir de uma divisao pronta")
    public WorkoutDto fromTemplate(@AuthenticationPrincipal AuthPrincipal principal,
                                   @Valid @RequestBody TemplateRequest request) {
        return service.createFromTemplate(principal.userId(), request);
    }

    @PutMapping("/{id}")
    public WorkoutDto update(@AuthenticationPrincipal AuthPrincipal principal,
                             @PathVariable Long id,
                             @Valid @RequestBody WorkoutRequest request) {
        return service.update(principal.userId(), id, request);
    }

    @PostMapping("/{id}/duplicate")
    public WorkoutDto duplicate(@AuthenticationPrincipal AuthPrincipal principal,
                                @PathVariable Long id,
                                @RequestBody(required = false) Map<String, String> body) {
        String name = body == null ? null : body.get("name");
        return service.duplicate(principal.userId(), id, name);
    }

    @DeleteMapping("/{id}")
    public Map<String, Object> delete(@AuthenticationPrincipal AuthPrincipal principal, @PathVariable Long id) {
        service.delete(principal.userId(), id);
        return Map.of("deleted", true);
    }
}

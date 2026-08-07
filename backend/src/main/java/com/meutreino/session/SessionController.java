package com.meutreino.session;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.meutreino.common.PageResponse;
import com.meutreino.security.AuthPrincipal;
import com.meutreino.session.dto.SessionDtos.AddExerciseRequest;
import com.meutreino.session.dto.SessionDtos.AddSetRequest;
import com.meutreino.session.dto.SessionDtos.FinishSessionRequest;
import com.meutreino.session.dto.SessionDtos.SessionDto;
import com.meutreino.session.dto.SessionDtos.SessionSummaryDto;
import com.meutreino.session.dto.SessionDtos.StartSessionRequest;
import com.meutreino.session.dto.SessionDtos.SubstituteRequest;
import com.meutreino.session.dto.SessionDtos.UpdateSessionExerciseRequest;
import com.meutreino.session.dto.SessionDtos.UpdateSetRequest;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/sessions")
@Tag(name = "Sessoes de treino")
public class SessionController {

    private final SessionService service;

    public SessionController(SessionService service) {
        this.service = service;
    }

    @PostMapping("/start")
    @Operation(summary = "Inicia uma sessao a partir de um dia do treino")
    public SessionDto start(@AuthenticationPrincipal AuthPrincipal principal,
                            @RequestBody StartSessionRequest request) {
        return service.start(principal.userId(), request);
    }

    @GetMapping("/active")
    @Operation(summary = "Sessao em andamento, se existir")
    public ResponseEntity<SessionDto> active(@AuthenticationPrincipal AuthPrincipal principal) {
        return service.active(principal.userId())
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    @GetMapping
    @Operation(summary = "Historico de treinos concluidos")
    public PageResponse<SessionSummaryDto> history(@AuthenticationPrincipal AuthPrincipal principal,
                                                  @RequestParam(defaultValue = "0") int page,
                                                  @RequestParam(defaultValue = "20") int size) {
        return service.history(principal.userId(), page, size);
    }

    @GetMapping("/{id}")
    public SessionDto get(@AuthenticationPrincipal AuthPrincipal principal, @PathVariable Long id) {
        return service.get(principal.userId(), id);
    }

    @PatchMapping("/{id}/sets/{setId}")
    @Operation(summary = "Atualiza carga, repeticoes, RPE ou marca a serie como concluida")
    public SessionDto updateSet(@AuthenticationPrincipal AuthPrincipal principal,
                                @PathVariable Long id,
                                @PathVariable Long setId,
                                @Valid @RequestBody UpdateSetRequest request) {
        return service.updateSet(principal.userId(), id, setId, request);
    }

    @PostMapping("/{id}/exercises/{sessionExerciseId}/sets")
    public SessionDto addSet(@AuthenticationPrincipal AuthPrincipal principal,
                             @PathVariable Long id,
                             @PathVariable Long sessionExerciseId,
                             @RequestBody(required = false) AddSetRequest request) {
        return service.addSet(principal.userId(), id, sessionExerciseId, request);
    }

    @DeleteMapping("/{id}/sets/{setId}")
    public SessionDto removeSet(@AuthenticationPrincipal AuthPrincipal principal,
                                @PathVariable Long id,
                                @PathVariable Long setId) {
        return service.removeSet(principal.userId(), id, setId);
    }

    @PatchMapping("/{id}/exercises/{sessionExerciseId}")
    @Operation(summary = "Atualiza descanso e observacoes do exercicio na sessao")
    public SessionDto updateExercise(@AuthenticationPrincipal AuthPrincipal principal,
                                     @PathVariable Long id,
                                     @PathVariable Long sessionExerciseId,
                                     @Valid @RequestBody UpdateSessionExerciseRequest request) {
        return service.updateExercise(principal.userId(), id, sessionExerciseId, request);
    }

    @PostMapping("/{id}/exercises/{sessionExerciseId}/substitute")
    @Operation(summary = "Troca o exercicio somente nesta sessao")
    public SessionDto substitute(@AuthenticationPrincipal AuthPrincipal principal,
                                 @PathVariable Long id,
                                 @PathVariable Long sessionExerciseId,
                                 @Valid @RequestBody SubstituteRequest request) {
        return service.substitute(principal.userId(), id, sessionExerciseId, request);
    }

    @PostMapping("/{id}/exercises")
    public SessionDto addExercise(@AuthenticationPrincipal AuthPrincipal principal,
                                  @PathVariable Long id,
                                  @Valid @RequestBody AddExerciseRequest request) {
        return service.addExercise(principal.userId(), id, request);
    }

    @DeleteMapping("/{id}/exercises/{sessionExerciseId}")
    public SessionDto removeExercise(@AuthenticationPrincipal AuthPrincipal principal,
                                     @PathVariable Long id,
                                     @PathVariable Long sessionExerciseId) {
        return service.removeExercise(principal.userId(), id, sessionExerciseId);
    }

    @PostMapping("/{id}/finish")
    public SessionDto finish(@AuthenticationPrincipal AuthPrincipal principal,
                             @PathVariable Long id,
                             @RequestBody(required = false) FinishSessionRequest request) {
        return service.finish(principal.userId(), id, request);
    }

    @PostMapping("/{id}/cancel")
    public SessionDto cancel(@AuthenticationPrincipal AuthPrincipal principal, @PathVariable Long id) {
        return service.cancel(principal.userId(), id);
    }

    @DeleteMapping("/{id}")
    public Map<String, Object> delete(@AuthenticationPrincipal AuthPrincipal principal, @PathVariable Long id) {
        service.delete(principal.userId(), id);
        return Map.of("deleted", true);
    }
}

package com.meutreino.exercise;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.meutreino.common.PageResponse;
import com.meutreino.exercise.dto.CatalogDtos.CatalogDto;
import com.meutreino.exercise.dto.ExerciseDtos.ExerciseDetail;
import com.meutreino.exercise.dto.ExerciseDtos.ExerciseSummary;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/exercises")
@Tag(name = "Exercicios")
public class ExerciseController {

    private final ExerciseService service;
    private final CatalogService catalogService;

    public ExerciseController(ExerciseService service, CatalogService catalogService) {
        this.service = service;
        this.catalogService = catalogService;
    }

    @GetMapping
    @Operation(summary = "Pesquisa exercicios com filtros de musculo, equipamento e categoria")
    public PageResponse<ExerciseSummary> search(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) Integer categoryId,
            @RequestParam(required = false) Integer muscleId,
            @RequestParam(required = false) Integer equipmentId,
            @RequestParam(defaultValue = "false") boolean onlyWithImage,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return service.search(search, categoryId, muscleId, equipmentId, onlyWithImage, page, size);
    }

    @GetMapping("/catalog")
    @Operation(summary = "Musculos, equipamentos e categorias disponiveis")
    public CatalogDto catalog() {
        return catalogService.catalog();
    }

    @GetMapping("/{id}")
    public ExerciseDetail detail(@PathVariable Long id) {
        return service.detail(id);
    }

    @GetMapping("/{id}/equivalents")
    @Operation(summary = "Exercicios equivalentes (para troca durante o treino)")
    public List<ExerciseSummary> equivalents(@PathVariable Long id,
                                            @RequestParam(defaultValue = "15") int limit) {
        return service.equivalents(id, Math.min(Math.max(limit, 1), 50));
    }
}

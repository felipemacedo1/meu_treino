package com.meutreino.workout.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public final class WorkoutDtos {

    private WorkoutDtos() {
    }

    // ----------------------------- respostas -----------------------------

    public record WorkoutExerciseDto(
            Long id,
            Long exerciseId,
            String exerciseName,
            String imageUrl,
            List<String> primaryMuscles,
            List<String> equipment,
            int orderIndex,
            int targetSets,
            String targetReps,
            BigDecimal targetWeight,
            int restSeconds,
            String notes,
            BigDecimal lastWeight,
            BigDecimal bestWeight) {
    }

    public record WorkoutDayDto(
            Long id,
            String label,
            String name,
            int orderIndex,
            List<WorkoutExerciseDto> exercises) {
    }

    public record WorkoutDto(
            Long id,
            String name,
            String notes,
            String splitType,
            String color,
            boolean archived,
            Instant createdAt,
            Instant updatedAt,
            List<WorkoutDayDto> days) {
    }

    public record WorkoutSummaryDto(
            Long id,
            String name,
            String splitType,
            String color,
            boolean archived,
            Instant createdAt,
            int dayCount,
            int exerciseCount,
            List<DayLabelDto> days,
            Instant lastSessionAt) {
    }

    public record DayLabelDto(Long id, String label, String name, int exerciseCount) {
    }

    // ----------------------------- requisicoes ----------------------------

    public record WorkoutExerciseRequest(
            Long id,
            @NotNull(message = "Informe o exercicio") Long exerciseId,
            @Min(1) @Max(20) Integer targetSets,
            @Size(max = 20) String targetReps,
            BigDecimal targetWeight,
            @Min(0) @Max(900) Integer restSeconds,
            String notes) {
    }

    public record WorkoutDayRequest(
            Long id,
            @NotBlank(message = "Informe o rotulo do dia") @Size(max = 12) String label,
            @NotBlank(message = "Informe o nome do dia") @Size(max = 140) String name,
            @Valid List<WorkoutExerciseRequest> exercises) {
    }

    public record WorkoutRequest(
            @NotBlank(message = "Informe o nome do treino") @Size(max = 140) String name,
            String notes,
            String splitType,
            String color,
            Boolean archived,
            @Valid List<WorkoutDayRequest> days) {
    }

    public record TemplateRequest(
            @NotBlank(message = "Informe a divisao") String splitType,
            String name,
            String color) {
    }

    public record SplitOptionDto(String code, String name, String description, List<String> dayNames) {
    }
}

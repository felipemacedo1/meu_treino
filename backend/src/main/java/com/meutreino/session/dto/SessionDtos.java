package com.meutreino.session.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

public final class SessionDtos {

    private SessionDtos() {
    }

    // ----------------------------- respostas -----------------------------

    public record SessionSetDto(
            Long id,
            int setNumber,
            String targetReps,
            Integer reps,
            BigDecimal weight,
            boolean completed,
            Instant completedAt,
            Integer rpe) {
    }

    public record SessionExerciseDto(
            Long id,
            Long exerciseId,
            String exerciseName,
            String imageUrl,
            List<String> primaryMuscles,
            List<String> equipment,
            int orderIndex,
            int restSeconds,
            String notes,
            boolean substituted,
            String originalExerciseName,
            BigDecimal lastWeight,
            Integer lastReps,
            Instant lastDate,
            BigDecimal bestWeight,
            List<SessionSetDto> sets) {
    }

    public record SessionDto(
            Long id,
            Long workoutId,
            Long workoutDayId,
            String workoutName,
            String dayLabel,
            String dayName,
            String status,
            Instant startedAt,
            Instant finishedAt,
            Integer durationSeconds,
            BigDecimal totalVolume,
            int totalSets,
            String notes,
            List<SessionExerciseDto> exercises) {
    }

    public record SessionSummaryDto(
            Long id,
            Long workoutId,
            String workoutName,
            String dayLabel,
            String dayName,
            String status,
            Instant startedAt,
            Instant finishedAt,
            Integer durationSeconds,
            BigDecimal totalVolume,
            int totalSets,
            int exerciseCount) {
    }

    // ---------------------------- requisicoes ----------------------------

    public record StartSessionRequest(Long workoutId, Long workoutDayId, Boolean discardActive) {
    }

    public record UpdateSetRequest(
            @Min(0) @Max(999) Integer reps,
            BigDecimal weight,
            Boolean completed,
            @Min(1) @Max(10) Integer rpe) {
    }

    public record AddSetRequest(@Min(0) @Max(999) Integer reps, BigDecimal weight) {
    }

    public record UpdateSessionExerciseRequest(
            @Min(0) @Max(900) Integer restSeconds,
            String notes) {
    }

    public record SubstituteRequest(@NotNull(message = "Informe o exercicio substituto") Long exerciseId) {
    }

    public record AddExerciseRequest(
            @NotNull(message = "Informe o exercicio") Long exerciseId,
            @Min(1) @Max(20) Integer sets,
            String targetReps,
            @Min(0) @Max(900) Integer restSeconds) {
    }

    public record FinishSessionRequest(String notes, Integer durationSeconds) {
    }
}

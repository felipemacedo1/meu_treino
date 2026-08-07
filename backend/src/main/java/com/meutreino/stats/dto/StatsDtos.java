package com.meutreino.stats.dto;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;

public final class StatsDtos {

    private StatsDtos() {
    }

    public record OverviewDto(
            long totalSessions,
            BigDecimal totalVolume,
            long totalSets,
            long totalMinutes,
            int currentStreak,
            int longestStreak,
            int sessionsThisWeek,
            int weeklyGoal,
            BigDecimal volumeThisWeek,
            int avgSessionMinutes,
            Instant lastSessionAt,
            long workoutCount) {
    }

    public record WeeklyVolumeDto(LocalDate weekStart, BigDecimal volume, int sessions) {
    }

    public record MuscleGroupVolumeDto(String group, BigDecimal volume, long sets) {
    }

    public record ProgressionPointDto(
            LocalDate date,
            BigDecimal topWeight,
            BigDecimal volume,
            int sets,
            int reps,
            BigDecimal estimatedOneRepMax) {
    }

    public record ExerciseProgressionDto(
            Long exerciseId,
            String exerciseName,
            BigDecimal bestWeight,
            BigDecimal lastWeight,
            Instant lastDate,
            List<ProgressionPointDto> points) {
    }

    public record CalendarDayDto(LocalDate date, int sessions, BigDecimal volume) {
    }
}

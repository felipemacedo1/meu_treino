package com.meutreino.user.dto;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public final class ProfileDtos {

    private ProfileDtos() {
    }

    public record ProfileDto(
            Long userId,
            String name,
            String email,
            BigDecimal weightKg,
            Integer heightCm,
            LocalDate birthDate,
            String gender,
            String goal,
            String experience,
            Integer availableDays,
            Integer sessionMinutes,
            Integer weeklyGoal,
            String theme,
            Double bmi) {
    }

    public record ProfileUpdateRequest(
            String name,
            @DecimalMin(value = "20.0") @DecimalMax(value = "400.0") BigDecimal weightKg,
            @Min(80) @Max(260) Integer heightCm,
            LocalDate birthDate,
            String gender,
            String goal,
            String experience,
            @Min(1) @Max(7) Integer availableDays,
            @Min(10) @Max(300) Integer sessionMinutes,
            @Min(1) @Max(14) Integer weeklyGoal,
            @Size(max = 40) String theme) {
    }

    public record BodyWeightRequest(
            @NotNull @DecimalMin(value = "20.0") @DecimalMax(value = "400.0") BigDecimal weightKg,
            LocalDate measuredAt) {
    }

    public record BodyWeightPoint(LocalDate date, BigDecimal weightKg) {
    }

    public record BodyWeightHistory(List<BodyWeightPoint> points) {
    }
}

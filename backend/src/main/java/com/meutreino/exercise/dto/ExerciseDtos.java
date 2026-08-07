package com.meutreino.exercise.dto;

import java.util.List;

import com.meutreino.exercise.dto.CatalogDtos.MuscleDto;

public final class ExerciseDtos {

    private ExerciseDtos() {
    }

    public record ExerciseSummary(
            Long id,
            String name,
            String originalName,
            String categoryName,
            Integer categoryId,
            String imageUrl,
            List<String> primaryMuscles,
            List<String> equipment,
            boolean hasVideo) {
    }

    public record ExerciseDetail(
            Long id,
            Integer wgerId,
            String name,
            String originalName,
            String description,
            Integer categoryId,
            String categoryName,
            List<String> images,
            List<String> videos,
            List<MuscleDto> primaryMuscles,
            List<MuscleDto> secondaryMuscles,
            List<CatalogDtos.EquipmentDto> equipment) {
    }
}

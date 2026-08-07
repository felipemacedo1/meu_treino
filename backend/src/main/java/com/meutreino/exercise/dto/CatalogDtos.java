package com.meutreino.exercise.dto;

import java.util.List;

public final class CatalogDtos {

    private CatalogDtos() {
    }

    public record MuscleDto(Integer id, String name, String scientificName, boolean front, String imageUrl) {
    }

    public record EquipmentDto(Integer id, String name) {
    }

    public record CategoryDto(Integer id, String name) {
    }

    public record CatalogDto(List<MuscleDto> muscles,
                             List<EquipmentDto> equipment,
                             List<CategoryDto> categories,
                             long totalExercises) {
    }
}

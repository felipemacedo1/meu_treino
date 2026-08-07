package com.meutreino.exercise;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

import org.springframework.stereotype.Component;

import com.meutreino.exercise.dto.CatalogDtos.EquipmentDto;
import com.meutreino.exercise.dto.CatalogDtos.MuscleDto;
import com.meutreino.exercise.dto.ExerciseDtos.ExerciseDetail;
import com.meutreino.exercise.dto.ExerciseDtos.ExerciseSummary;
import com.meutreino.media.MediaService;

@Component
public class ExerciseMapper {

    private final CatalogService catalog;
    private final MediaService media;

    public ExerciseMapper(CatalogService catalog, MediaService media) {
        this.catalog = catalog;
        this.media = media;
    }

    public ExerciseSummary toSummary(Exercise exercise) {
        return new ExerciseSummary(
                exercise.getId(),
                exercise.displayName(),
                exercise.getName(),
                exercise.getCategory() == null ? null : exercise.getCategory().displayName(),
                exercise.getCategory() == null ? null : exercise.getCategory().getId(),
                mainImageUrl(exercise),
                muscleNames(exercise, true),
                exercise.getEquipment().stream()
                        .map(Equipment::displayName)
                        .sorted()
                        .toList(),
                !exercise.getVideos().isEmpty());
    }

    public ExerciseDetail toDetail(Exercise exercise) {
        return new ExerciseDetail(
                exercise.getId(),
                exercise.getWgerId(),
                exercise.displayName(),
                exercise.getName(),
                exercise.getDescription(),
                exercise.getCategory() == null ? null : exercise.getCategory().getId(),
                exercise.getCategory() == null ? null : exercise.getCategory().displayName(),
                imageUrls(exercise),
                exercise.getVideos().stream().map(media::publicUrl).toList(),
                muscleDtos(exercise, true),
                muscleDtos(exercise, false),
                exercise.getEquipment().stream()
                        .map(e -> new EquipmentDto(e.getId(), e.displayName()))
                        .sorted(Comparator.comparing(EquipmentDto::name))
                        .toList());
    }

    public String mainImageUrl(Exercise exercise) {
        return exercise.getImages().stream()
                .sorted(Comparator.comparing((ExerciseMedia m) -> Boolean.TRUE.equals(m.getMain()) ? 0 : 1))
                .map(ExerciseMedia::getUrl)
                .findFirst()
                .map(media::publicUrl)
                .orElse(null);
    }

    private List<String> imageUrls(Exercise exercise) {
        return exercise.getImages().stream()
                .sorted(Comparator.comparing((ExerciseMedia m) -> Boolean.TRUE.equals(m.getMain()) ? 0 : 1))
                .map(ExerciseMedia::getUrl)
                .map(media::publicUrl)
                .toList();
    }

    private List<String> muscleNames(Exercise exercise, boolean primary) {
        List<String> names = new ArrayList<>();
        for (ExerciseMuscleRef ref : exercise.getMuscles()) {
            if (ref.isPrimaryMuscle() == primary) {
                String name = catalog.muscleName(ref.getMuscleId());
                if (name != null && !names.contains(name)) {
                    names.add(name);
                }
            }
        }
        names.sort(Comparator.naturalOrder());
        return names;
    }

    private List<MuscleDto> muscleDtos(Exercise exercise, boolean primary) {
        List<MuscleDto> dtos = new ArrayList<>();
        for (ExerciseMuscleRef ref : exercise.getMuscles()) {
            if (ref.isPrimaryMuscle() == primary) {
                MuscleDto dto = catalog.muscleDto(ref.getMuscleId());
                if (dto != null && dtos.stream().noneMatch(d -> d.id().equals(dto.id()))) {
                    dtos.add(dto);
                }
            }
        }
        dtos.sort(Comparator.comparing(MuscleDto::name));
        return dtos;
    }
}

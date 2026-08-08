package com.meutreino.exercise;

import java.util.ArrayList;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.meutreino.common.ApiExceptions.NotFoundException;
import com.meutreino.common.PageResponse;
import com.meutreino.exercise.dto.ExerciseDtos.ExerciseDetail;
import com.meutreino.exercise.dto.ExerciseDtos.ExerciseSummary;

@Service
public class ExerciseService {

    private final ExerciseRepository repository;
    private final ExerciseMapper mapper;

    public ExerciseService(ExerciseRepository repository, ExerciseMapper mapper) {
        this.repository = repository;
        this.mapper = mapper;
    }

    @Transactional(readOnly = true)
    public PageResponse<ExerciseSummary> search(String search,
                                                Integer categoryId,
                                                Integer muscleId,
                                                Integer equipmentId,
                                                boolean onlyWithImage,
                                                boolean onlyWithVideo,
                                                int page,
                                                int size) {
        List<Specification<Exercise>> specs = new ArrayList<>();
        specs.add(ExerciseSpecs.search(search));
        specs.add(ExerciseSpecs.category(categoryId));
        specs.add(ExerciseSpecs.muscle(muscleId));
        specs.add(ExerciseSpecs.equipment(equipmentId));
        specs.add(ExerciseSpecs.onlyWithImage(onlyWithImage));
        specs.add(ExerciseSpecs.onlyWithVideo(onlyWithVideo));

        Pageable pageable = PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100),
                Sort.by(Sort.Order.desc("quality"), Sort.Order.asc("name")));
        Page<Exercise> result = repository.findAll(ExerciseSpecs.all(specs), pageable);
        return PageResponse.of(result, mapper::toSummary);
    }

    @Transactional(readOnly = true)
    public ExerciseDetail detail(Long id) {
        Exercise exercise = repository.findWithDetailsById(id)
                .orElseThrow(() -> new NotFoundException("Exercicio nao encontrado"));
        return mapper.toDetail(exercise);
    }

    @Transactional(readOnly = true)
    public Exercise require(Long id) {
        return repository.findById(id)
                .orElseThrow(() -> new NotFoundException("Exercicio " + id + " nao encontrado"));
    }

    /** Exercicios equivalentes para a troca durante a sessao. */
    @Transactional(readOnly = true)
    public List<ExerciseSummary> equivalents(Long exerciseId, int limit) {
        Exercise exercise = repository.findWithDetailsById(exerciseId)
                .orElseThrow(() -> new NotFoundException("Exercicio nao encontrado"));
        List<Integer> primaryMuscles = exercise.getMuscles().stream()
                .filter(ExerciseMuscleRef::isPrimaryMuscle)
                .map(ExerciseMuscleRef::getMuscleId)
                .toList();

        List<Exercise> candidates;
        if (primaryMuscles.isEmpty()) {
            Integer categoryId = exercise.getCategory() == null ? null : exercise.getCategory().getId();
            candidates = repository.findAll(
                    ExerciseSpecs.all(List.of(
                            ExerciseSpecs.category(categoryId),
                            ExerciseSpecs.onlyWithImage(false))),
                    PageRequest.of(0, limit + 1, Sort.by("name"))).getContent();
        } else {
            candidates = repository.findEquivalents(exerciseId, primaryMuscles, PageRequest.of(0, limit + 20));
        }

        Integer categoryId = exercise.getCategory() == null ? null : exercise.getCategory().getId();
        return candidates.stream()
                .filter(e -> !e.getId().equals(exerciseId))
                .sorted((a, b) -> Integer.compare(score(b, categoryId), score(a, categoryId)))
                .limit(limit)
                .map(mapper::toSummary)
                .toList();
    }

    /** Prioriza mesma categoria e exercicios com imagem. */
    private int score(Exercise exercise, Integer categoryId) {
        int score = 0;
        if (categoryId != null && exercise.getCategory() != null
                && categoryId.equals(exercise.getCategory().getId())) {
            score += 10;
        }
        if (!exercise.getImages().isEmpty()) {
            score += 3;
        }
        if (exercise.getNamePt() != null) {
            score += 1;
        }
        return score;
    }
}

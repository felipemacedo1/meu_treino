package com.meutreino.workout;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Set;

import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.meutreino.common.ApiExceptions.BadRequestException;
import com.meutreino.common.ApiExceptions.NotFoundException;
import com.meutreino.exercise.Exercise;
import com.meutreino.exercise.ExerciseMapper;
import com.meutreino.exercise.ExerciseRepository;
import com.meutreino.session.ExerciseHistoryService;
import com.meutreino.session.ExerciseHistoryService.ExerciseHistory;
import com.meutreino.session.SessionRepository;
import com.meutreino.workout.SplitTemplates.Slot;
import com.meutreino.workout.SplitTemplates.Template;
import com.meutreino.workout.dto.WorkoutDtos.DayLabelDto;
import com.meutreino.workout.dto.WorkoutDtos.SplitOptionDto;
import com.meutreino.workout.dto.WorkoutDtos.TemplateRequest;
import com.meutreino.workout.dto.WorkoutDtos.WorkoutDayDto;
import com.meutreino.workout.dto.WorkoutDtos.WorkoutDayRequest;
import com.meutreino.workout.dto.WorkoutDtos.WorkoutDto;
import com.meutreino.workout.dto.WorkoutDtos.WorkoutExerciseDto;
import com.meutreino.workout.dto.WorkoutDtos.WorkoutExerciseRequest;
import com.meutreino.workout.dto.WorkoutDtos.WorkoutRequest;
import com.meutreino.workout.dto.WorkoutDtos.WorkoutSummaryDto;

@Service
public class WorkoutService {

    private final WorkoutRepository workoutRepository;
    private final ExerciseRepository exerciseRepository;
    private final ExerciseMapper exerciseMapper;
    private final ExerciseHistoryService historyService;
    private final SessionRepository sessionRepository;

    public WorkoutService(WorkoutRepository workoutRepository,
                          ExerciseRepository exerciseRepository,
                          ExerciseMapper exerciseMapper,
                          ExerciseHistoryService historyService,
                          SessionRepository sessionRepository) {
        this.workoutRepository = workoutRepository;
        this.exerciseRepository = exerciseRepository;
        this.exerciseMapper = exerciseMapper;
        this.historyService = historyService;
        this.sessionRepository = sessionRepository;
    }

    // -------------------------------- leitura --------------------------------

    @Transactional(readOnly = true)
    public List<WorkoutSummaryDto> list(Long userId, boolean includeArchived) {
        List<Workout> workouts = includeArchived
                ? workoutRepository.findByUserIdOrderByCreatedAtDesc(userId)
                : workoutRepository.findByUserIdAndArchivedFalseOrderByCreatedAtDesc(userId);
        List<WorkoutSummaryDto> result = new ArrayList<>();
        for (Workout workout : workouts) {
            int exerciseCount = workout.getDays().stream().mapToInt(d -> d.getExercises().size()).sum();
            result.add(new WorkoutSummaryDto(
                    workout.getId(),
                    workout.getName(),
                    workout.getSplitType(),
                    workout.getColor(),
                    workout.isArchived(),
                    workout.getCreatedAt(),
                    workout.getDays().size(),
                    exerciseCount,
                    workout.getDays().stream()
                            .map(d -> new DayLabelDto(d.getId(), d.getLabel(), d.getName(), d.getExercises().size()))
                            .toList(),
                    sessionRepository.lastSessionAt(userId, workout.getId())));
        }
        return result;
    }

    @Transactional(readOnly = true)
    public WorkoutDto get(Long userId, Long workoutId) {
        return toDto(require(userId, workoutId), historyService.historyByExercise(userId));
    }

    @Transactional(readOnly = true)
    public Workout require(Long userId, Long workoutId) {
        return workoutRepository.findByIdAndUserId(workoutId, userId)
                .orElseThrow(() -> new NotFoundException("Treino nao encontrado"));
    }

    // -------------------------------- escrita --------------------------------

    @Transactional
    public WorkoutDto create(Long userId, WorkoutRequest request) {
        Workout workout = new Workout();
        workout.setUserId(userId);
        apply(workout, request);
        workoutRepository.save(workout);
        return toDto(workout, historyService.historyByExercise(userId));
    }

    @Transactional
    public WorkoutDto update(Long userId, Long workoutId, WorkoutRequest request) {
        Workout workout = require(userId, workoutId);
        apply(workout, request);
        workoutRepository.save(workout);
        return toDto(workout, historyService.historyByExercise(userId));
    }

    @Transactional
    public void delete(Long userId, Long workoutId) {
        Workout workout = require(userId, workoutId);
        workoutRepository.delete(workout);
    }

    @Transactional
    public WorkoutDto duplicate(Long userId, Long workoutId, String newName) {
        Workout source = require(userId, workoutId);
        Workout copy = new Workout();
        copy.setUserId(userId);
        copy.setName(newName != null && !newName.isBlank() ? newName.trim() : source.getName() + " (copia)");
        copy.setNotes(source.getNotes());
        copy.setSplitType(source.getSplitType());
        copy.setColor(source.getColor());
        for (WorkoutDay day : source.getDays()) {
            WorkoutDay dayCopy = new WorkoutDay();
            dayCopy.setLabel(day.getLabel());
            dayCopy.setName(day.getName());
            dayCopy.setOrderIndex(day.getOrderIndex());
            for (WorkoutExercise exercise : day.getExercises()) {
                WorkoutExercise exerciseCopy = new WorkoutExercise();
                exerciseCopy.setExercise(exercise.getExercise());
                exerciseCopy.setOrderIndex(exercise.getOrderIndex());
                exerciseCopy.setTargetSets(exercise.getTargetSets());
                exerciseCopy.setTargetReps(exercise.getTargetReps());
                exerciseCopy.setTargetWeight(exercise.getTargetWeight());
                exerciseCopy.setRestSeconds(exercise.getRestSeconds());
                exerciseCopy.setNotes(exercise.getNotes());
                dayCopy.getExercises().add(exerciseCopy);
            }
            copy.getDays().add(dayCopy);
        }
        workoutRepository.save(copy);
        return toDto(copy, historyService.historyByExercise(userId));
    }

    private void apply(Workout workout, WorkoutRequest request) {
        workout.setName(request.name().trim());
        workout.setNotes(request.notes());
        workout.setSplitType(request.splitType() == null ? "CUSTOM" : request.splitType().toUpperCase());
        workout.setColor(request.color());
        if (request.archived() != null) {
            workout.setArchived(request.archived());
        }
        workout.setUpdatedAt(Instant.now());

        List<WorkoutDayRequest> dayRequests = request.days() == null ? List.of() : request.days();
        if (dayRequests.isEmpty()) {
            throw new BadRequestException("O treino precisa de pelo menos um dia");
        }

        Map<Long, WorkoutDay> existingDays = new HashMap<>();
        workout.getDays().forEach(d -> existingDays.put(d.getId(), d));

        List<WorkoutDay> newDays = new ArrayList<>();
        int dayIndex = 0;
        for (WorkoutDayRequest dayRequest : dayRequests) {
            WorkoutDay day = dayRequest.id() == null ? new WorkoutDay() : existingDays.get(dayRequest.id());
            if (day == null) {
                day = new WorkoutDay();
            }
            day.setLabel(dayRequest.label().trim());
            day.setName(dayRequest.name().trim());
            day.setOrderIndex(dayIndex++);

            Map<Long, WorkoutExercise> existingExercises = new HashMap<>();
            day.getExercises().forEach(e -> existingExercises.put(e.getId(), e));

            List<WorkoutExercise> newExercises = new ArrayList<>();
            List<WorkoutExerciseRequest> exerciseRequests =
                    dayRequest.exercises() == null ? List.of() : dayRequest.exercises();
            int exerciseIndex = 0;
            for (WorkoutExerciseRequest exerciseRequest : exerciseRequests) {
                WorkoutExercise exercise = exerciseRequest.id() == null
                        ? new WorkoutExercise()
                        : existingExercises.getOrDefault(exerciseRequest.id(), new WorkoutExercise());
                exercise.setExercise(exerciseRepository.findById(exerciseRequest.exerciseId())
                        .orElseThrow(() -> new NotFoundException(
                                "Exercicio " + exerciseRequest.exerciseId() + " nao encontrado")));
                exercise.setOrderIndex(exerciseIndex++);
                exercise.setTargetSets(exerciseRequest.targetSets() == null ? 3 : exerciseRequest.targetSets());
                exercise.setTargetReps(exerciseRequest.targetReps() == null || exerciseRequest.targetReps().isBlank()
                        ? "10" : exerciseRequest.targetReps().trim());
                exercise.setTargetWeight(exerciseRequest.targetWeight());
                exercise.setRestSeconds(exerciseRequest.restSeconds() == null ? 90 : exerciseRequest.restSeconds());
                exercise.setNotes(exerciseRequest.notes());
                newExercises.add(exercise);
            }
            day.getExercises().clear();
            day.getExercises().addAll(newExercises);
            newDays.add(day);
        }
        workout.getDays().clear();
        workout.getDays().addAll(newDays);
    }

    // ------------------------------- templates -------------------------------

    public List<SplitOptionDto> splitOptions() {
        return SplitTemplates.all().stream()
                .map(t -> new SplitOptionDto(t.code(), t.name(), t.description(),
                        t.days().stream().map(SplitTemplates.Day::name).toList()))
                .toList();
    }

    @Transactional
    public WorkoutDto createFromTemplate(Long userId, TemplateRequest request) {
        Template template = SplitTemplates.get(request.splitType());
        if (template == null) {
            throw new BadRequestException("Divisao desconhecida: " + request.splitType());
        }
        Workout workout = new Workout();
        workout.setUserId(userId);
        workout.setName(request.name() == null || request.name().isBlank()
                ? "Treino " + template.name() : request.name().trim());
        workout.setSplitType(template.code());
        workout.setColor(request.color());
        workout.setNotes(template.description());

        int dayIndex = 0;
        for (SplitTemplates.Day templateDay : template.days()) {
            WorkoutDay day = new WorkoutDay();
            day.setLabel(templateDay.label());
            day.setName(templateDay.name());
            day.setOrderIndex(dayIndex++);

            Set<Long> used = new LinkedHashSet<>();
            int exerciseIndex = 0;
            for (Slot slot : templateDay.slots()) {
                Optional<Exercise> resolved = resolve(slot, used);
                if (resolved.isEmpty()) {
                    continue;
                }
                Exercise exercise = resolved.get();
                used.add(exercise.getId());

                WorkoutExercise workoutExercise = new WorkoutExercise();
                workoutExercise.setExercise(exercise);
                workoutExercise.setOrderIndex(exerciseIndex++);
                workoutExercise.setTargetSets(slot.sets());
                workoutExercise.setTargetReps(slot.reps());
                workoutExercise.setRestSeconds(slot.rest());
                day.getExercises().add(workoutExercise);
            }
            workout.getDays().add(day);
        }
        workoutRepository.save(workout);
        return toDto(workout, historyService.historyByExercise(userId));
    }

    private Optional<Exercise> resolve(Slot slot, Set<Long> used) {
        for (String name : slot.preferredNames()) {
            Optional<Exercise> exact = exerciseRepository.findByNameIgnoreCase(name).stream()
                    .filter(e -> !used.contains(e.getId()))
                    .findFirst();
            if (exact.isPresent()) {
                return exact;
            }
            Optional<Exercise> partial = exerciseRepository
                    .findByNameContaining(name, PageRequest.of(0, 10)).stream()
                    .filter(e -> !used.contains(e.getId()))
                    .findFirst();
            if (partial.isPresent()) {
                return partial;
            }
        }
        if (slot.categoryId() != null) {
            return exerciseRepository.findByCategoryWithImage(slot.categoryId(), PageRequest.of(0, 30)).stream()
                    .filter(e -> !used.contains(e.getId()))
                    .findFirst();
        }
        return Optional.empty();
    }

    // -------------------------------- mapeamento -----------------------------

    public WorkoutDto toDto(Workout workout, Map<Long, ExerciseHistory> history) {
        List<WorkoutDayDto> days = workout.getDays().stream()
                .map(day -> new WorkoutDayDto(
                        day.getId(),
                        day.getLabel(),
                        day.getName(),
                        day.getOrderIndex(),
                        day.getExercises().stream().map(e -> toDto(e, history)).toList()))
                .toList();
        return new WorkoutDto(
                workout.getId(),
                workout.getName(),
                workout.getNotes(),
                workout.getSplitType(),
                workout.getColor(),
                workout.isArchived(),
                workout.getCreatedAt(),
                workout.getUpdatedAt(),
                days);
    }

    private WorkoutExerciseDto toDto(WorkoutExercise workoutExercise, Map<Long, ExerciseHistory> history) {
        Exercise exercise = workoutExercise.getExercise();
        var summary = exerciseMapper.toSummary(exercise);
        ExerciseHistory exerciseHistory = history.get(exercise.getId());
        return new WorkoutExerciseDto(
                workoutExercise.getId(),
                exercise.getId(),
                summary.name(),
                summary.imageUrl(),
                summary.primaryMuscles(),
                summary.equipment(),
                workoutExercise.getOrderIndex(),
                workoutExercise.getTargetSets(),
                workoutExercise.getTargetReps(),
                workoutExercise.getTargetWeight(),
                workoutExercise.getRestSeconds(),
                workoutExercise.getNotes(),
                exerciseHistory == null ? null : exerciseHistory.lastWeight(),
                exerciseHistory == null ? null : exerciseHistory.bestWeight());
    }
}

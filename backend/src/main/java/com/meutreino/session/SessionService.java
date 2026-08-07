package com.meutreino.session;

import java.math.BigDecimal;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.meutreino.common.ApiExceptions.BadRequestException;
import com.meutreino.common.ApiExceptions.ConflictException;
import com.meutreino.common.ApiExceptions.NotFoundException;
import com.meutreino.common.PageResponse;
import com.meutreino.exercise.Exercise;
import com.meutreino.exercise.ExerciseMapper;
import com.meutreino.exercise.ExerciseRepository;
import com.meutreino.session.ExerciseHistoryService.ExerciseHistory;
import com.meutreino.session.dto.SessionDtos.AddExerciseRequest;
import com.meutreino.session.dto.SessionDtos.AddSetRequest;
import com.meutreino.session.dto.SessionDtos.FinishSessionRequest;
import com.meutreino.session.dto.SessionDtos.SessionDto;
import com.meutreino.session.dto.SessionDtos.SessionExerciseDto;
import com.meutreino.session.dto.SessionDtos.SessionSetDto;
import com.meutreino.session.dto.SessionDtos.SessionSummaryDto;
import com.meutreino.session.dto.SessionDtos.StartSessionRequest;
import com.meutreino.session.dto.SessionDtos.SubstituteRequest;
import com.meutreino.session.dto.SessionDtos.UpdateSessionExerciseRequest;
import com.meutreino.session.dto.SessionDtos.UpdateSetRequest;
import com.meutreino.workout.Workout;
import com.meutreino.workout.WorkoutDay;
import com.meutreino.workout.WorkoutExercise;
import com.meutreino.workout.WorkoutRepository;

@Service
public class SessionService {

    private final SessionRepository sessionRepository;
    private final WorkoutRepository workoutRepository;
    private final ExerciseRepository exerciseRepository;
    private final ExerciseMapper exerciseMapper;
    private final ExerciseHistoryService historyService;

    public SessionService(SessionRepository sessionRepository,
                          WorkoutRepository workoutRepository,
                          ExerciseRepository exerciseRepository,
                          ExerciseMapper exerciseMapper,
                          ExerciseHistoryService historyService) {
        this.sessionRepository = sessionRepository;
        this.workoutRepository = workoutRepository;
        this.exerciseRepository = exerciseRepository;
        this.exerciseMapper = exerciseMapper;
        this.historyService = historyService;
    }

    // ------------------------------- inicio ---------------------------------

    @Transactional
    public SessionDto start(Long userId, StartSessionRequest request) {
        Optional<Session> active = sessionRepository
                .findFirstByUserIdAndStatusOrderByStartedAtDesc(userId, Session.IN_PROGRESS);
        if (active.isPresent()) {
            if (!Boolean.TRUE.equals(request.discardActive())) {
                throw new ConflictException("Ja existe um treino em andamento");
            }
            Session previous = active.get();
            previous.setStatus(Session.CANCELED);
            previous.setFinishedAt(Instant.now());
            sessionRepository.save(previous);
        }

        Session session = new Session();
        session.setUserId(userId);
        session.setStartedAt(Instant.now());
        session.setStatus(Session.IN_PROGRESS);

        if (request.workoutId() != null) {
            Workout workout = workoutRepository.findByIdAndUserId(request.workoutId(), userId)
                    .orElseThrow(() -> new NotFoundException("Treino nao encontrado"));
            WorkoutDay day = resolveDay(workout, request.workoutDayId());
            session.setWorkoutId(workout.getId());
            session.setWorkoutName(workout.getName());
            session.setWorkoutDayId(day.getId());
            session.setDayLabel(day.getLabel());
            session.setDayName(day.getName());

            for (WorkoutExercise workoutExercise : day.getExercises()) {
                SessionExercise sessionExercise = new SessionExercise();
                sessionExercise.setWorkoutExerciseId(workoutExercise.getId());
                sessionExercise.setExercise(workoutExercise.getExercise());
                sessionExercise.setOrderIndex(workoutExercise.getOrderIndex());
                sessionExercise.setRestSeconds(workoutExercise.getRestSeconds());
                sessionExercise.setNotes(workoutExercise.getNotes());
                for (int i = 1; i <= Math.max(workoutExercise.getTargetSets(), 1); i++) {
                    SessionSet set = new SessionSet();
                    set.setSetNumber(i);
                    set.setTargetReps(workoutExercise.getTargetReps());
                    set.setWeight(workoutExercise.getTargetWeight());
                    sessionExercise.getSets().add(set);
                }
                session.getExercises().add(sessionExercise);
            }
        } else {
            session.setWorkoutName("Treino livre");
            session.setDayName("Treino livre");
            session.setDayLabel("L");
        }

        sessionRepository.save(session);
        return toDto(session, historyService.historyByExercise(userId));
    }

    private WorkoutDay resolveDay(Workout workout, Long workoutDayId) {
        if (workout.getDays().isEmpty()) {
            throw new BadRequestException("O treino nao possui dias configurados");
        }
        if (workoutDayId == null) {
            return workout.getDays().get(0);
        }
        return workout.getDays().stream()
                .filter(d -> d.getId().equals(workoutDayId))
                .findFirst()
                .orElseThrow(() -> new NotFoundException("Dia do treino nao encontrado"));
    }

    // ------------------------------- leitura --------------------------------

    @Transactional(readOnly = true)
    public Optional<SessionDto> active(Long userId) {
        return sessionRepository.findFirstByUserIdAndStatusOrderByStartedAtDesc(userId, Session.IN_PROGRESS)
                .map(session -> toDto(session, historyService.historyByExercise(userId)));
    }

    @Transactional(readOnly = true)
    public SessionDto get(Long userId, Long sessionId) {
        return toDto(require(userId, sessionId), historyService.historyByExercise(userId));
    }

    @Transactional(readOnly = true)
    public PageResponse<SessionSummaryDto> history(Long userId, int page, int size) {
        Page<Session> sessions = sessionRepository.findByUserIdAndStatusOrderByStartedAtDesc(
                userId, Session.FINISHED, PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), 100)));
        return PageResponse.of(sessions, this::toSummary);
    }

    // ------------------------------- escrita --------------------------------

    @Transactional
    public SessionDto updateSet(Long userId, Long sessionId, Long setId, UpdateSetRequest request) {
        Session session = requireInProgressOrFinished(userId, sessionId);
        SessionSet set = findSet(session, setId);
        if (request.reps() != null) {
            set.setReps(request.reps());
        }
        if (request.weight() != null) {
            set.setWeight(request.weight());
        }
        if (request.rpe() != null) {
            set.setRpe(request.rpe());
        }
        if (request.completed() != null) {
            set.setCompleted(request.completed());
            set.setCompletedAt(request.completed() ? Instant.now() : null);
        }
        recalculate(session);
        sessionRepository.save(session);
        return toDto(session, historyService.historyByExercise(userId));
    }

    @Transactional
    public SessionDto addSet(Long userId, Long sessionId, Long sessionExerciseId, AddSetRequest request) {
        Session session = requireInProgressOrFinished(userId, sessionId);
        SessionExercise sessionExercise = findExercise(session, sessionExerciseId);
        int nextNumber = sessionExercise.getSets().stream()
                .mapToInt(SessionSet::getSetNumber)
                .max()
                .orElse(0) + 1;
        SessionSet set = new SessionSet();
        set.setSetNumber(nextNumber);
        set.setReps(request == null ? null : request.reps());
        if (request != null && request.weight() != null) {
            set.setWeight(request.weight());
        } else {
            sessionExercise.getSets().stream()
                    .filter(s -> s.getWeight() != null)
                    .reduce((first, second) -> second)
                    .ifPresent(last -> set.setWeight(last.getWeight()));
        }
        sessionExercise.getSets().stream()
                .filter(s -> s.getTargetReps() != null)
                .findFirst()
                .ifPresent(s -> set.setTargetReps(s.getTargetReps()));
        sessionExercise.getSets().add(set);
        sessionRepository.save(session);
        return toDto(session, historyService.historyByExercise(userId));
    }

    @Transactional
    public SessionDto removeSet(Long userId, Long sessionId, Long setId) {
        Session session = requireInProgressOrFinished(userId, sessionId);
        for (SessionExercise sessionExercise : session.getExercises()) {
            boolean removed = sessionExercise.getSets().removeIf(s -> s.getId().equals(setId));
            if (removed) {
                int number = 1;
                for (SessionSet set : sessionExercise.getSets()) {
                    set.setSetNumber(number++);
                }
                recalculate(session);
                sessionRepository.save(session);
                return toDto(session, historyService.historyByExercise(userId));
            }
        }
        throw new NotFoundException("Serie nao encontrada");
    }

    @Transactional
    public SessionDto updateExercise(Long userId, Long sessionId, Long sessionExerciseId,
                                     UpdateSessionExerciseRequest request) {
        Session session = requireInProgressOrFinished(userId, sessionId);
        SessionExercise sessionExercise = findExercise(session, sessionExerciseId);
        if (request.restSeconds() != null) {
            sessionExercise.setRestSeconds(request.restSeconds());
        }
        if (request.notes() != null) {
            sessionExercise.setNotes(request.notes());
        }
        sessionRepository.save(session);
        return toDto(session, historyService.historyByExercise(userId));
    }

    /**
     * Troca o exercicio apenas nesta sessao (o treino salvo continua igual).
     */
    @Transactional
    public SessionDto substitute(Long userId, Long sessionId, Long sessionExerciseId, SubstituteRequest request) {
        Session session = requireInProgress(userId, sessionId);
        SessionExercise sessionExercise = findExercise(session, sessionExerciseId);
        Exercise replacement = exerciseRepository.findById(request.exerciseId())
                .orElseThrow(() -> new NotFoundException("Exercicio nao encontrado"));
        if (sessionExercise.getOriginalExercise() == null) {
            sessionExercise.setOriginalExercise(sessionExercise.getExercise());
        }
        sessionExercise.setExercise(replacement);
        sessionRepository.save(session);
        return toDto(session, historyService.historyByExercise(userId));
    }

    @Transactional
    public SessionDto addExercise(Long userId, Long sessionId, AddExerciseRequest request) {
        Session session = requireInProgress(userId, sessionId);
        Exercise exercise = exerciseRepository.findById(request.exerciseId())
                .orElseThrow(() -> new NotFoundException("Exercicio nao encontrado"));
        SessionExercise sessionExercise = new SessionExercise();
        sessionExercise.setExercise(exercise);
        sessionExercise.setOrderIndex(session.getExercises().size());
        sessionExercise.setRestSeconds(request.restSeconds() == null ? 90 : request.restSeconds());
        int sets = request.sets() == null ? 3 : request.sets();
        String reps = request.targetReps() == null || request.targetReps().isBlank() ? "10" : request.targetReps();
        for (int i = 1; i <= sets; i++) {
            SessionSet set = new SessionSet();
            set.setSetNumber(i);
            set.setTargetReps(reps);
            sessionExercise.getSets().add(set);
        }
        session.getExercises().add(sessionExercise);
        sessionRepository.save(session);
        return toDto(session, historyService.historyByExercise(userId));
    }

    @Transactional
    public SessionDto removeExercise(Long userId, Long sessionId, Long sessionExerciseId) {
        Session session = requireInProgress(userId, sessionId);
        boolean removed = session.getExercises().removeIf(e -> e.getId().equals(sessionExerciseId));
        if (!removed) {
            throw new NotFoundException("Exercicio da sessao nao encontrado");
        }
        int index = 0;
        for (SessionExercise sessionExercise : session.getExercises()) {
            sessionExercise.setOrderIndex(index++);
        }
        recalculate(session);
        sessionRepository.save(session);
        return toDto(session, historyService.historyByExercise(userId));
    }

    @Transactional
    public SessionDto finish(Long userId, Long sessionId, FinishSessionRequest request) {
        Session session = requireInProgress(userId, sessionId);
        if (request != null && request.notes() != null) {
            session.setNotes(request.notes());
        }
        recalculate(session);
        session.setStatus(Session.FINISHED);
        session.setFinishedAt(Instant.now());
        int duration = request != null && request.durationSeconds() != null
                ? request.durationSeconds()
                : (int) Duration.between(session.getStartedAt(), session.getFinishedAt()).toSeconds();
        session.setDurationSeconds(Math.max(duration, 0));
        sessionRepository.save(session);
        return toDto(session, historyService.historyByExercise(userId));
    }

    @Transactional
    public SessionDto cancel(Long userId, Long sessionId) {
        Session session = requireInProgress(userId, sessionId);
        session.setStatus(Session.CANCELED);
        session.setFinishedAt(Instant.now());
        sessionRepository.save(session);
        return toDto(session, historyService.historyByExercise(userId));
    }

    @Transactional
    public void delete(Long userId, Long sessionId) {
        sessionRepository.delete(require(userId, sessionId));
    }

    // ------------------------------ auxiliares ------------------------------

    private void recalculate(Session session) {
        BigDecimal volume = BigDecimal.ZERO;
        int totalSets = 0;
        for (SessionExercise sessionExercise : session.getExercises()) {
            for (SessionSet set : sessionExercise.getSets()) {
                if (set.isCompleted()) {
                    totalSets++;
                    if (set.getWeight() != null && set.getReps() != null) {
                        volume = volume.add(set.getWeight().multiply(BigDecimal.valueOf(set.getReps())));
                    }
                }
            }
        }
        session.setTotalVolume(volume);
        session.setTotalSets(totalSets);
    }

    private Session require(Long userId, Long sessionId) {
        return sessionRepository.findByIdAndUserId(sessionId, userId)
                .orElseThrow(() -> new NotFoundException("Sessao nao encontrada"));
    }

    private Session requireInProgress(Long userId, Long sessionId) {
        Session session = require(userId, sessionId);
        if (!Session.IN_PROGRESS.equals(session.getStatus())) {
            throw new BadRequestException("Esta sessao ja foi finalizada");
        }
        return session;
    }

    private Session requireInProgressOrFinished(Long userId, Long sessionId) {
        Session session = require(userId, sessionId);
        if (Session.CANCELED.equals(session.getStatus())) {
            throw new BadRequestException("Esta sessao foi cancelada");
        }
        return session;
    }

    private SessionExercise findExercise(Session session, Long sessionExerciseId) {
        return session.getExercises().stream()
                .filter(e -> e.getId().equals(sessionExerciseId))
                .findFirst()
                .orElseThrow(() -> new NotFoundException("Exercicio da sessao nao encontrado"));
    }

    private SessionSet findSet(Session session, Long setId) {
        return session.getExercises().stream()
                .flatMap(e -> e.getSets().stream())
                .filter(s -> s.getId().equals(setId))
                .findFirst()
                .orElseThrow(() -> new NotFoundException("Serie nao encontrada"));
    }

    // ------------------------------ mapeamento ------------------------------

    public SessionDto toDto(Session session, Map<Long, ExerciseHistory> history) {
        List<SessionExerciseDto> exercises = session.getExercises().stream()
                .map(sessionExercise -> {
                    Exercise exercise = sessionExercise.getExercise();
                    var summary = exerciseMapper.toSummary(exercise);
                    ExerciseHistory exerciseHistory = history.get(exercise.getId());
                    return new SessionExerciseDto(
                            sessionExercise.getId(),
                            exercise.getId(),
                            summary.name(),
                            summary.imageUrl(),
                            summary.primaryMuscles(),
                            summary.equipment(),
                            sessionExercise.getOrderIndex(),
                            sessionExercise.getRestSeconds(),
                            sessionExercise.getNotes(),
                            sessionExercise.getOriginalExercise() != null,
                            sessionExercise.getOriginalExercise() == null
                                    ? null : sessionExercise.getOriginalExercise().displayName(),
                            exerciseHistory == null ? null : exerciseHistory.lastWeight(),
                            exerciseHistory == null ? null : exerciseHistory.lastReps(),
                            exerciseHistory == null ? null : exerciseHistory.lastDate(),
                            exerciseHistory == null ? null : exerciseHistory.bestWeight(),
                            sessionExercise.getSets().stream().map(this::toDto).toList());
                })
                .toList();

        return new SessionDto(
                session.getId(),
                session.getWorkoutId(),
                session.getWorkoutDayId(),
                session.getWorkoutName(),
                session.getDayLabel(),
                session.getDayName(),
                session.getStatus(),
                session.getStartedAt(),
                session.getFinishedAt(),
                session.getDurationSeconds(),
                session.getTotalVolume(),
                session.getTotalSets(),
                session.getNotes(),
                exercises);
    }

    private SessionSetDto toDto(SessionSet set) {
        return new SessionSetDto(
                set.getId(),
                set.getSetNumber(),
                set.getTargetReps(),
                set.getReps(),
                set.getWeight(),
                set.isCompleted(),
                set.getCompletedAt(),
                set.getRpe());
    }

    public SessionSummaryDto toSummary(Session session) {
        return new SessionSummaryDto(
                session.getId(),
                session.getWorkoutId(),
                session.getWorkoutName(),
                session.getDayLabel(),
                session.getDayName(),
                session.getStatus(),
                session.getStartedAt(),
                session.getFinishedAt(),
                session.getDurationSeconds(),
                session.getTotalVolume(),
                session.getTotalSets(),
                session.getExercises().size());
    }
}

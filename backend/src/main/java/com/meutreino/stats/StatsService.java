package com.meutreino.stats;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeSet;

import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.meutreino.common.ApiExceptions.NotFoundException;
import com.meutreino.exercise.Exercise;
import com.meutreino.exercise.ExerciseRepository;
import com.meutreino.common.Values;
import com.meutreino.session.Session;
import com.meutreino.session.SessionRepository;
import com.meutreino.session.SessionSetRepository;
import com.meutreino.stats.dto.StatsDtos.CalendarDayDto;
import com.meutreino.stats.dto.StatsDtos.ExerciseProgressionDto;
import com.meutreino.stats.dto.StatsDtos.MuscleGroupVolumeDto;
import com.meutreino.stats.dto.StatsDtos.OverviewDto;
import com.meutreino.stats.dto.StatsDtos.ProgressionPointDto;
import com.meutreino.stats.dto.StatsDtos.WeeklyVolumeDto;
import com.meutreino.user.Profile;
import com.meutreino.user.ProfileRepository;
import com.meutreino.workout.WorkoutRepository;

@Service
public class StatsService {

    private static final ZoneId ZONE = ZoneId.systemDefault();

    private final SessionRepository sessionRepository;
    private final SessionSetRepository sessionSetRepository;
    private final WorkoutRepository workoutRepository;
    private final ProfileRepository profileRepository;
    private final ExerciseRepository exerciseRepository;

    public StatsService(SessionRepository sessionRepository,
                        SessionSetRepository sessionSetRepository,
                        WorkoutRepository workoutRepository,
                        ProfileRepository profileRepository,
                        ExerciseRepository exerciseRepository) {
        this.sessionRepository = sessionRepository;
        this.sessionSetRepository = sessionSetRepository;
        this.workoutRepository = workoutRepository;
        this.profileRepository = profileRepository;
        this.exerciseRepository = exerciseRepository;
    }

    @Transactional(readOnly = true)
    public OverviewDto overview(Long userId) {
        long totalSessions = sessionRepository.countByUserIdAndStatus(userId, Session.FINISHED);
        BigDecimal totalVolume = nz(sessionRepository.totalVolume(userId));
        long totalSets = nz(sessionRepository.totalSets(userId));
        long totalSeconds = nz(sessionRepository.totalDuration(userId));

        List<Instant> dates = sessionRepository.finishedDates(userId, PageRequest.of(0, 500));
        TreeSet<LocalDate> days = new TreeSet<>();
        dates.forEach(instant -> days.add(LocalDate.ofInstant(instant, ZONE)));

        int currentStreak = currentStreak(days);
        int longestStreak = longestStreak(days);

        LocalDate weekStart = LocalDate.now(ZONE).with(DayOfWeek.MONDAY);
        Instant weekStartInstant = weekStart.atStartOfDay(ZONE).toInstant();
        List<Session> weekSessions = sessionRepository
                .findByUserIdAndStatusAndStartedAtAfterOrderByStartedAtAsc(userId, Session.FINISHED, weekStartInstant);
        BigDecimal volumeThisWeek = weekSessions.stream()
                .map(Session::getTotalVolume)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Profile profile = profileRepository.findById(userId).orElse(null);
        int weeklyGoal = profile == null || profile.getWeeklyGoal() == null ? 4 : profile.getWeeklyGoal();

        int avgMinutes = totalSessions == 0 ? 0 : (int) Math.round(totalSeconds / 60.0 / totalSessions);

        return new OverviewDto(
                totalSessions,
                totalVolume.setScale(1, RoundingMode.HALF_UP),
                totalSets,
                totalSeconds / 60,
                currentStreak,
                longestStreak,
                weekSessions.size(),
                weeklyGoal,
                volumeThisWeek.setScale(1, RoundingMode.HALF_UP),
                avgMinutes,
                dates.isEmpty() ? null : dates.get(0),
                workoutRepository.countByUserId(userId));
    }

    @Transactional(readOnly = true)
    public List<WeeklyVolumeDto> weeklyVolume(Long userId, int weeks) {
        int safeWeeks = Math.min(Math.max(weeks, 1), 52);
        LocalDate firstWeek = LocalDate.now(ZONE).with(DayOfWeek.MONDAY).minusWeeks(safeWeeks - 1L);
        Instant since = firstWeek.atStartOfDay(ZONE).toInstant();

        Map<LocalDate, WeeklyVolumeDto> byWeek = new LinkedHashMap<>();
        for (int i = 0; i < safeWeeks; i++) {
            LocalDate week = firstWeek.plusWeeks(i);
            byWeek.put(week, new WeeklyVolumeDto(week, BigDecimal.ZERO, 0));
        }
        for (Object[] row : sessionSetRepository.weeklyVolume(userId, since)) {
            LocalDate week = toLocalDate(row[0]);
            if (week == null) {
                continue;
            }
            LocalDate key = week.with(DayOfWeek.MONDAY);
            BigDecimal volume = Values.toBigDecimal(row[1]);
            int sessions = row[2] == null ? 0 : ((Number) row[2]).intValue();
            byWeek.put(key, new WeeklyVolumeDto(key,
                    volume == null ? BigDecimal.ZERO : volume.setScale(1, RoundingMode.HALF_UP), sessions));
        }
        return new ArrayList<>(byWeek.values());
    }

    @Transactional(readOnly = true)
    public List<MuscleGroupVolumeDto> muscleGroups(Long userId, int days) {
        Instant since = LocalDate.now(ZONE).minusDays(Math.max(days, 1)).atStartOfDay(ZONE).toInstant();
        List<MuscleGroupVolumeDto> result = new ArrayList<>();
        for (Object[] row : sessionSetRepository.volumeByMuscleGroup(userId, since)) {
            BigDecimal volume = Values.toBigDecimal(row[1]);
            result.add(new MuscleGroupVolumeDto(
                    row[0] == null ? "Outros" : row[0].toString(),
                    volume == null ? BigDecimal.ZERO : volume.setScale(1, RoundingMode.HALF_UP),
                    row[2] == null ? 0 : ((Number) row[2]).longValue()));
        }
        return result;
    }

    @Transactional(readOnly = true)
    public ExerciseProgressionDto exerciseProgression(Long userId, Long exerciseId) {
        Exercise exercise = exerciseRepository.findById(exerciseId)
                .orElseThrow(() -> new NotFoundException("Exercicio nao encontrado"));

        List<ProgressionPointDto> points = new ArrayList<>();
        BigDecimal best = null;
        BigDecimal last = null;
        Instant lastDate = null;

        for (Object[] row : sessionSetRepository.exerciseProgression(userId, exerciseId)) {
            Instant date = Values.toInstant(row[0]);
            BigDecimal topWeight = Values.toBigDecimal(row[1]);
            BigDecimal volume = Values.toBigDecimal(row[2]);
            int sets = row[3] == null ? 0 : ((Number) row[3]).intValue();
            int reps = row[4] == null ? 0 : ((Number) row[4]).intValue();

            BigDecimal oneRepMax = null;
            if (topWeight != null && sets > 0 && reps > 0) {
                int avgReps = Math.max(reps / Math.max(sets, 1), 1);
                oneRepMax = topWeight
                        .multiply(BigDecimal.valueOf(1 + avgReps / 30.0))
                        .setScale(1, RoundingMode.HALF_UP);
            }

            points.add(new ProgressionPointDto(
                    date == null ? null : LocalDate.ofInstant(date, ZONE),
                    topWeight,
                    volume == null ? BigDecimal.ZERO : volume.setScale(1, RoundingMode.HALF_UP),
                    sets,
                    reps,
                    oneRepMax));

            if (topWeight != null && (best == null || topWeight.compareTo(best) > 0)) {
                best = topWeight;
            }
            if (topWeight != null) {
                last = topWeight;
                lastDate = date;
            }
        }

        return new ExerciseProgressionDto(exerciseId, exercise.displayName(), best, last, lastDate, points);
    }

    @Transactional(readOnly = true)
    public List<CalendarDayDto> calendar(Long userId, int days) {
        int safeDays = Math.min(Math.max(days, 7), 365);
        Instant since = LocalDate.now(ZONE).minusDays(safeDays).atStartOfDay(ZONE).toInstant();
        List<Session> sessions = sessionRepository
                .findByUserIdAndStatusAndStartedAtAfterOrderByStartedAtAsc(userId, Session.FINISHED, since);

        Map<LocalDate, CalendarDayDto> byDay = new LinkedHashMap<>();
        for (Session session : sessions) {
            LocalDate day = LocalDate.ofInstant(session.getStartedAt(), ZONE);
            CalendarDayDto current = byDay.get(day);
            BigDecimal volume = nz(session.getTotalVolume());
            if (current == null) {
                byDay.put(day, new CalendarDayDto(day, 1, volume));
            } else {
                byDay.put(day, new CalendarDayDto(day, current.sessions() + 1, current.volume().add(volume)));
            }
        }
        return new ArrayList<>(byDay.values());
    }

    // ------------------------------ auxiliares ------------------------------

    private int currentStreak(TreeSet<LocalDate> days) {
        if (days.isEmpty()) {
            return 0;
        }
        LocalDate today = LocalDate.now(ZONE);
        LocalDate cursor = days.contains(today) ? today
                : (days.contains(today.minusDays(1)) ? today.minusDays(1) : null);
        if (cursor == null) {
            return 0;
        }
        int streak = 0;
        while (days.contains(cursor)) {
            streak++;
            cursor = cursor.minusDays(1);
        }
        return streak;
    }

    private int longestStreak(TreeSet<LocalDate> days) {
        int longest = 0;
        int current = 0;
        LocalDate previous = null;
        for (LocalDate day : days) {
            if (previous != null && ChronoUnit.DAYS.between(previous, day) == 1) {
                current++;
            } else {
                current = 1;
            }
            longest = Math.max(longest, current);
            previous = day;
        }
        return longest;
    }

    private static BigDecimal nz(BigDecimal value) {
        return value == null ? BigDecimal.ZERO : value;
    }

    private static long nz(Long value) {
        return value == null ? 0L : value;
    }

    private static LocalDate toLocalDate(Object value) {
        Instant instant = Values.toInstant(value);
        if (instant != null) {
            return LocalDate.ofInstant(instant, ZONE);
        }
        if (value instanceof java.sql.Date date) {
            return date.toLocalDate();
        }
        if (value instanceof LocalDate localDate) {
            return localDate;
        }
        return null;
    }
}

package com.meutreino.session;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.meutreino.common.Values;

/**
 * Consultas de historico por exercicio, usadas para mostrar
 * "carga anterior" e "melhor carga" na tela de treino.
 */
@Service
public class ExerciseHistoryService {

    private final SessionSetRepository sessionSetRepository;

    public ExerciseHistoryService(SessionSetRepository sessionSetRepository) {
        this.sessionSetRepository = sessionSetRepository;
    }

    public record ExerciseHistory(BigDecimal lastWeight, Integer lastReps, Instant lastDate, BigDecimal bestWeight) {
    }

    @Transactional(readOnly = true)
    public Map<Long, ExerciseHistory> historyByExercise(Long userId) {
        Map<Long, BigDecimal> best = new HashMap<>();
        for (Object[] row : sessionSetRepository.bestWeightByExercise(userId)) {
            best.put(Values.toLong(row[0]), Values.toBigDecimal(row[1]));
        }
        Map<Long, ExerciseHistory> result = new HashMap<>();
        for (Object[] row : sessionSetRepository.lastPerformanceByExercise(userId)) {
            Long exerciseId = Values.toLong(row[0]);
            result.put(exerciseId, new ExerciseHistory(
                    Values.toBigDecimal(row[1]),
                    Values.toInteger(row[2]),
                    Values.toInstant(row[3]),
                    best.get(exerciseId)));
        }
        best.forEach((exerciseId, weight) ->
                result.computeIfAbsent(exerciseId, id -> new ExerciseHistory(null, null, null, weight)));
        return result;
    }
}

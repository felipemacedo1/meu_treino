package com.meutreino.session;

import java.time.Instant;
import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SessionSetRepository extends JpaRepository<SessionSet, Long> {

    /** Melhor carga registrada por exercicio. */
    @Query(value = """
            SELECT se.exercise_id, MAX(ss.weight)
            FROM session_sets ss
            JOIN session_exercises se ON se.id = ss.session_exercise_id
            JOIN sessions s ON s.id = se.session_id
            WHERE s.user_id = :userId
              AND ss.completed = TRUE
              AND ss.weight IS NOT NULL
            GROUP BY se.exercise_id
            """, nativeQuery = true)
    List<Object[]> bestWeightByExercise(@Param("userId") Long userId);

    /** Ultima execucao (carga/reps/data) por exercicio. */
    @Query(value = """
            SELECT DISTINCT ON (se.exercise_id)
                   se.exercise_id, ss.weight, ss.reps, s.started_at
            FROM session_sets ss
            JOIN session_exercises se ON se.id = ss.session_exercise_id
            JOIN sessions s ON s.id = se.session_id
            WHERE s.user_id = :userId
              AND ss.completed = TRUE
              AND ss.weight IS NOT NULL
            ORDER BY se.exercise_id, s.started_at DESC, ss.weight DESC
            """, nativeQuery = true)
    List<Object[]> lastPerformanceByExercise(@Param("userId") Long userId);

    /** Evolucao de um exercicio ao longo das sessoes. */
    @Query(value = """
            SELECT s.started_at,
                   MAX(ss.weight),
                   COALESCE(SUM(ss.weight * ss.reps), 0),
                   COUNT(*),
                   COALESCE(SUM(ss.reps), 0)
            FROM session_sets ss
            JOIN session_exercises se ON se.id = ss.session_exercise_id
            JOIN sessions s ON s.id = se.session_id
            WHERE s.user_id = :userId
              AND se.exercise_id = :exerciseId
              AND ss.completed = TRUE
            GROUP BY s.id, s.started_at
            ORDER BY s.started_at ASC
            """, nativeQuery = true)
    List<Object[]> exerciseProgression(@Param("userId") Long userId, @Param("exerciseId") Long exerciseId);

    /** Volume por semana. */
    @Query(value = """
            SELECT DATE_TRUNC('week', s.started_at) AS week,
                   COALESCE(SUM(ss.weight * ss.reps), 0) AS volume,
                   COUNT(DISTINCT s.id) AS sessions
            FROM sessions s
            LEFT JOIN session_exercises se ON se.session_id = s.id
            LEFT JOIN session_sets ss ON ss.session_exercise_id = se.id AND ss.completed = TRUE
            WHERE s.user_id = :userId
              AND s.status = 'FINISHED'
              AND s.started_at >= :since
            GROUP BY DATE_TRUNC('week', s.started_at)
            ORDER BY week ASC
            """, nativeQuery = true)
    List<Object[]> weeklyVolume(@Param("userId") Long userId, @Param("since") Instant since);

    /** Volume por grupo muscular (categoria do exercicio). */
    @Query(value = """
            SELECT COALESCE(c.name_pt, c.name, 'Outros') AS grupo,
                   COALESCE(SUM(ss.weight * ss.reps), 0) AS volume,
                   COUNT(*) AS sets
            FROM session_sets ss
            JOIN session_exercises se ON se.id = ss.session_exercise_id
            JOIN sessions s ON s.id = se.session_id
            JOIN exercises e ON e.id = se.exercise_id
            LEFT JOIN exercise_categories c ON c.id = e.category_id
            WHERE s.user_id = :userId
              AND s.status = 'FINISHED'
              AND ss.completed = TRUE
              AND s.started_at >= :since
            GROUP BY COALESCE(c.name_pt, c.name, 'Outros')
            ORDER BY volume DESC
            """, nativeQuery = true)
    List<Object[]> volumeByMuscleGroup(@Param("userId") Long userId, @Param("since") Instant since);
}

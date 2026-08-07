package com.meutreino.session;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface SessionRepository extends JpaRepository<Session, Long> {

    Optional<Session> findByIdAndUserId(Long id, Long userId);

    Optional<Session> findFirstByUserIdAndStatusOrderByStartedAtDesc(Long userId, String status);

    Page<Session> findByUserIdAndStatusOrderByStartedAtDesc(Long userId, String status, Pageable pageable);

    Page<Session> findByUserIdOrderByStartedAtDesc(Long userId, Pageable pageable);

    List<Session> findByUserIdAndStatusAndStartedAtAfterOrderByStartedAtAsc(
            Long userId, String status, Instant after);

    long countByUserIdAndStatus(Long userId, String status);

    @Query("SELECT COALESCE(SUM(s.totalVolume), 0) FROM Session s WHERE s.userId = :userId AND s.status = 'FINISHED'")
    java.math.BigDecimal totalVolume(@Param("userId") Long userId);

    @Query("SELECT COALESCE(SUM(s.totalSets), 0) FROM Session s WHERE s.userId = :userId AND s.status = 'FINISHED'")
    Long totalSets(@Param("userId") Long userId);

    @Query("SELECT COALESCE(SUM(s.durationSeconds), 0) FROM Session s WHERE s.userId = :userId AND s.status = 'FINISHED'")
    Long totalDuration(@Param("userId") Long userId);

    @Query("SELECT s.startedAt FROM Session s WHERE s.userId = :userId AND s.status = 'FINISHED' ORDER BY s.startedAt DESC")
    List<Instant> finishedDates(@Param("userId") Long userId, Pageable pageable);

    @Query("SELECT MAX(s.startedAt) FROM Session s WHERE s.userId = :userId AND s.workoutId = :workoutId AND s.status = 'FINISHED'")
    Instant lastSessionAt(@Param("userId") Long userId, @Param("workoutId") Long workoutId);
}

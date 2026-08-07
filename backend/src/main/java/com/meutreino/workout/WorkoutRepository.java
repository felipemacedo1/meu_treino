package com.meutreino.workout;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface WorkoutRepository extends JpaRepository<Workout, Long> {

    List<Workout> findByUserIdAndArchivedFalseOrderByCreatedAtDesc(Long userId);

    List<Workout> findByUserIdOrderByCreatedAtDesc(Long userId);

    Optional<Workout> findByIdAndUserId(Long id, Long userId);

    long countByUserId(Long userId);
}

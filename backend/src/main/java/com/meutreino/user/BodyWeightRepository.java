package com.meutreino.user;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface BodyWeightRepository extends JpaRepository<BodyWeight, Long> {

    List<BodyWeight> findByUserIdOrderByMeasuredAtAsc(Long userId);

    Optional<BodyWeight> findByUserIdAndMeasuredAt(Long userId, LocalDate measuredAt);
}

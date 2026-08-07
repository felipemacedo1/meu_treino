package com.meutreino.wger;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface SyncLogRepository extends JpaRepository<SyncLog, Long> {

    Optional<SyncLog> findFirstByOrderByStartedAtDesc();

    List<SyncLog> findTop10ByOrderByStartedAtDesc();
}

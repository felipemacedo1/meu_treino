package com.meutreino.wger;

import java.time.Instant;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "sync_log")
@Getter
@Setter
public class SyncLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String source = "WGER";

    /** RUNNING, SUCCESS, ERROR */
    @Column(nullable = false)
    private String status = "RUNNING";

    @Column(nullable = false)
    private int exercises;

    @Column(columnDefinition = "text")
    private String message;

    @Column(name = "started_at", nullable = false)
    private Instant startedAt = Instant.now();

    @Column(name = "finished_at")
    private Instant finishedAt;
}

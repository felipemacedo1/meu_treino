package com.meutreino.session;

import java.math.BigDecimal;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "sessions")
@Getter
@Setter
public class Session {

    public static final String IN_PROGRESS = "IN_PROGRESS";
    public static final String FINISHED = "FINISHED";
    public static final String CANCELED = "CANCELED";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(name = "workout_id")
    private Long workoutId;

    @Column(name = "workout_day_id")
    private Long workoutDayId;

    @Column(name = "workout_name")
    private String workoutName;

    @Column(name = "day_label")
    private String dayLabel;

    @Column(name = "day_name")
    private String dayName;

    @Column(nullable = false)
    private String status = IN_PROGRESS;

    @Column(name = "started_at", nullable = false)
    private Instant startedAt = Instant.now();

    @Column(name = "finished_at")
    private Instant finishedAt;

    @Column(name = "duration_seconds")
    private Integer durationSeconds;

    @Column(name = "total_volume", nullable = false)
    private BigDecimal totalVolume = BigDecimal.ZERO;

    @Column(name = "total_sets", nullable = false)
    private int totalSets;

    @Column(columnDefinition = "text")
    private String notes;

    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    @OrderBy("orderIndex ASC")
    private List<SessionExercise> exercises = new ArrayList<>();
}

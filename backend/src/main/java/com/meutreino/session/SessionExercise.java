package com.meutreino.session;

import java.util.ArrayList;
import java.util.List;

import com.meutreino.exercise.Exercise;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "session_exercises")
@Getter
@Setter
public class SessionExercise {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "workout_exercise_id")
    private Long workoutExerciseId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;

    /** Preenchido quando o exercicio foi trocado durante a sessao. */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "original_exercise_id")
    private Exercise originalExercise;

    @Column(name = "order_index", nullable = false)
    private int orderIndex;

    @Column(name = "rest_seconds", nullable = false)
    private int restSeconds = 90;

    @Column(columnDefinition = "text")
    private String notes;

    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.LAZY)
    @JoinColumn(name = "session_exercise_id", nullable = false)
    @OrderBy("setNumber ASC")
    private List<SessionSet> sets = new ArrayList<>();
}

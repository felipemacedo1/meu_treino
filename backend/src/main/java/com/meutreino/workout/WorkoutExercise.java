package com.meutreino.workout;

import java.math.BigDecimal;

import com.meutreino.exercise.Exercise;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "workout_exercises")
@Getter
@Setter
public class WorkoutExercise {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;

    @Column(name = "order_index", nullable = false)
    private int orderIndex;

    @Column(name = "target_sets", nullable = false)
    private int targetSets = 3;

    @Column(name = "target_reps", nullable = false)
    private String targetReps = "10";

    @Column(name = "target_weight")
    private BigDecimal targetWeight;

    @Column(name = "rest_seconds", nullable = false)
    private int restSeconds = 90;

    @Column(columnDefinition = "text")
    private String notes;
}

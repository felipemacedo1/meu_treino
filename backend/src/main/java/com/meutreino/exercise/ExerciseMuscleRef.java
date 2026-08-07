package com.meutreino.exercise;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import lombok.AllArgsConstructor;
import lombok.EqualsAndHashCode;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Embeddable
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@EqualsAndHashCode
public class ExerciseMuscleRef {

    @Column(name = "muscle_id", nullable = false)
    private Integer muscleId;

    @Column(name = "is_primary", nullable = false)
    private boolean primaryMuscle;
}

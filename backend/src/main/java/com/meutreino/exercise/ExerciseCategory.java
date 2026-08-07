package com.meutreino.exercise;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "exercise_categories")
@Getter
@Setter
public class ExerciseCategory {

    @Id
    private Integer id;

    @Column(nullable = false)
    private String name;

    @Column(name = "name_pt")
    private String namePt;

    public String displayName() {
        return (namePt != null && !namePt.isBlank()) ? namePt : name;
    }
}

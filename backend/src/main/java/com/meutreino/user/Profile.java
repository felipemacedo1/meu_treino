package com.meutreino.user;

import java.math.BigDecimal;
import java.time.Instant;
import java.time.LocalDate;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "profiles")
@Getter
@Setter
public class Profile {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @Column(name = "weight_kg")
    private BigDecimal weightKg;

    @Column(name = "height_cm")
    private Integer heightCm;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    private String gender;

    /** HIPERTROFIA, FORCA, EMAGRECIMENTO, RESISTENCIA, SAUDE */
    private String goal;

    /** INICIANTE, INTERMEDIARIO, AVANCADO */
    private String experience;

    @Column(name = "available_days")
    private Integer availableDays;

    @Column(name = "session_minutes")
    private Integer sessionMinutes;

    @Column(name = "weekly_goal")
    private Integer weeklyGoal;

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();
}

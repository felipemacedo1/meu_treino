package com.meutreino.exercise;

import java.time.Instant;
import java.util.LinkedHashSet;
import java.util.Set;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.JoinTable;
import jakarta.persistence.ManyToMany;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "exercises")
@Getter
@Setter
public class Exercise {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "wger_id", unique = true)
    private Integer wgerId;

    @Column(name = "uuid")
    private String uuid;

    @Column(nullable = false)
    private String name;

    @Column(name = "name_pt")
    private String namePt;

    /**
     * Marca traducoes curadas por nos. O sync do wger nao sobrescreve estes
     * nomes, porque algumas traducoes de lá estao erradas.
     */
    @Column(name = "name_pt_locked", nullable = false)
    private boolean namePtLocked = false;

    @Column(columnDefinition = "text")
    private String description;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "category_id")
    private ExerciseCategory category;

    @Column(nullable = false)
    private String source = "WGER";

    /** Ordenacao do catalogo: 2 (nome em PT) + 1 (tem imagem). */
    @Column(nullable = false)
    private short quality = 0;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(name = "exercise_muscles", joinColumns = @JoinColumn(name = "exercise_id"))
    private Set<ExerciseMuscleRef> muscles = new LinkedHashSet<>();

    @ManyToMany(fetch = FetchType.LAZY)
    @JoinTable(name = "exercise_equipment",
            joinColumns = @JoinColumn(name = "exercise_id"),
            inverseJoinColumns = @JoinColumn(name = "equipment_id"))
    private Set<Equipment> equipment = new LinkedHashSet<>();

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(name = "exercise_images", joinColumns = @JoinColumn(name = "exercise_id"))
    private Set<ExerciseMedia> images = new LinkedHashSet<>();

    @ElementCollection(fetch = FetchType.LAZY)
    @CollectionTable(name = "exercise_videos", joinColumns = @JoinColumn(name = "exercise_id"))
    @Column(name = "url")
    private Set<String> videos = new LinkedHashSet<>();

    public String displayName() {
        return (namePt != null && !namePt.isBlank()) ? namePt : name;
    }
}

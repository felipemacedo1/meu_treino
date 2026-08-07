package com.meutreino.exercise;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "muscles")
@Getter
@Setter
public class Muscle {

    @Id
    private Integer id;

    @Column(nullable = false)
    private String name;

    @Column(name = "name_pt")
    private String namePt;

    @Column(name = "name_en")
    private String nameEn;

    @Column(name = "is_front", nullable = false)
    private boolean front = true;

    @Column(name = "image_url_main")
    private String imageUrlMain;

    @Column(name = "image_url_secondary")
    private String imageUrlSecondary;

    public String displayName() {
        if (namePt != null && !namePt.isBlank()) {
            return namePt;
        }
        return (nameEn != null && !nameEn.isBlank()) ? nameEn : name;
    }
}

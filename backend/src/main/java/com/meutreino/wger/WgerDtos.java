package com.meutreino.wger;

import java.util.List;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.annotation.JsonProperty;

/**
 * Subconjunto da API v2 do wger que a gente realmente consome.
 * Fonte: https://wger.de/api/v2/exerciseinfo/
 */
public final class WgerDtos {

    private WgerDtos() {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record Page<T>(int count, String next, String previous, List<T> results) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record WgerCategory(Integer id, String name) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record WgerEquipment(Integer id, String name) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record WgerMuscle(
            Integer id,
            String name,
            @JsonProperty("name_en") String nameEn,
            @JsonProperty("is_front") Boolean front,
            @JsonProperty("image_url_main") String imageUrlMain,
            @JsonProperty("image_url_secondary") String imageUrlSecondary) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record WgerImage(Integer id, String image, @JsonProperty("is_main") Boolean main) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record WgerVideo(Integer id, String video) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record WgerTranslation(Integer id, String name, String description, Integer language) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    public record WgerExercise(
            Integer id,
            String uuid,
            WgerCategory category,
            List<WgerMuscle> muscles,
            @JsonProperty("muscles_secondary") List<WgerMuscle> musclesSecondary,
            List<WgerEquipment> equipment,
            List<WgerImage> images,
            List<WgerVideo> videos,
            List<WgerTranslation> translations) {
    }
}

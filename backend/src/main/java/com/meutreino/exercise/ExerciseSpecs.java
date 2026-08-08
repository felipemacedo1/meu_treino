package com.meutreino.exercise;

import java.util.ArrayList;
import java.util.List;

import org.springframework.data.jpa.domain.Specification;

import jakarta.persistence.criteria.JoinType;
import jakarta.persistence.criteria.Subquery;

public final class ExerciseSpecs {

    private ExerciseSpecs() {
    }

    public static Specification<Exercise> search(String term) {
        if (term == null || term.isBlank()) {
            return null;
        }
        String pattern = "%" + term.trim().toLowerCase() + "%";
        return (root, query, cb) -> cb.or(
                cb.like(cb.lower(root.get("name")), pattern),
                cb.like(cb.lower(cb.coalesce(root.get("namePt"), "")), pattern));
    }

    public static Specification<Exercise> category(Integer categoryId) {
        if (categoryId == null) {
            return null;
        }
        return (root, query, cb) -> cb.equal(root.get("category").get("id"), categoryId);
    }

    public static Specification<Exercise> muscle(Integer muscleId) {
        if (muscleId == null) {
            return null;
        }
        return (root, query, cb) -> {
            if (query != null) {
                query.distinct(true);
            }
            return cb.equal(root.joinSet("muscles", JoinType.INNER).get("muscleId"), muscleId);
        };
    }

    public static Specification<Exercise> equipment(Integer equipmentId) {
        if (equipmentId == null) {
            return null;
        }
        return (root, query, cb) -> {
            if (query != null) {
                query.distinct(true);
            }
            return cb.equal(root.joinSet("equipment", JoinType.INNER).get("id"), equipmentId);
        };
    }

    public static Specification<Exercise> onlyWithImage(boolean onlyWithImage) {
        return onlyWithImage ? hasMedia("images") : null;
    }

    public static Specification<Exercise> onlyWithVideo(boolean onlyWithVideo) {
        return onlyWithVideo ? hasMedia("videos") : null;
    }

    /** EXISTS na coleção de mídia informada ("images" ou "videos"). */
    private static Specification<Exercise> hasMedia(String collection) {
        return (root, query, cb) -> {
            if (query == null) {
                return cb.conjunction();
            }
            Subquery<Integer> sub = query.subquery(Integer.class);
            var subRoot = sub.from(Exercise.class);
            subRoot.joinSet(collection, JoinType.INNER);
            sub.select(cb.literal(1)).where(cb.equal(subRoot.get("id"), root.get("id")));
            return cb.exists(sub);
        };
    }

    public static Specification<Exercise> all(List<Specification<Exercise>> specs) {
        List<Specification<Exercise>> valid = new ArrayList<>();
        for (Specification<Exercise> spec : specs) {
            if (spec != null) {
                valid.add(spec);
            }
        }
        if (valid.isEmpty()) {
            return (root, query, cb) -> cb.conjunction();
        }
        Specification<Exercise> result = valid.get(0);
        for (int i = 1; i < valid.size(); i++) {
            result = result.and(valid.get(i));
        }
        return result;
    }
}

package com.meutreino.exercise;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ExerciseRepository extends JpaRepository<Exercise, Long>, JpaSpecificationExecutor<Exercise> {

    Optional<Exercise> findByWgerId(Integer wgerId);

    @EntityGraph(attributePaths = {"category", "equipment", "muscles", "images", "videos"})
    Optional<Exercise> findWithDetailsById(Long id);

    /**
     * Exercicios equivalentes: ao menos um musculo primario em comum.
     * Usado na troca de exercicio durante a sessao de treino.
     */
    @Query("""
            SELECT DISTINCT e FROM Exercise e
            JOIN e.muscles m
            WHERE e.id <> :exerciseId
              AND m.primaryMuscle = TRUE
              AND m.muscleId IN :muscleIds
            ORDER BY e.name
            """)
    List<Exercise> findEquivalents(@Param("exerciseId") Long exerciseId,
                                   @Param("muscleIds") List<Integer> muscleIds,
                                   Pageable pageable);

    @Query("SELECT COUNT(e) FROM Exercise e")
    long countAll();

    List<Exercise> findByNameIgnoreCase(String name);

    /** Busca o exercicio mais "canonico" que contem o termo (nome mais curto). */
    @Query("""
            SELECT e FROM Exercise e
            WHERE LOWER(e.name) LIKE LOWER(CONCAT('%', :term, '%'))
            ORDER BY LENGTH(e.name) ASC, e.name ASC
            """)
    List<Exercise> findByNameContaining(@Param("term") String term, Pageable pageable);

    /** Fallback: melhores exercicios de uma categoria (prioriza os que tem imagem). */
    @Query("""
            SELECT e FROM Exercise e
            WHERE e.category.id = :categoryId
              AND EXISTS (SELECT 1 FROM Exercise x JOIN x.images i WHERE x.id = e.id)
            ORDER BY LENGTH(e.name) ASC, e.name ASC
            """)
    List<Exercise> findByCategoryWithImage(@Param("categoryId") Integer categoryId, Pageable pageable);
}

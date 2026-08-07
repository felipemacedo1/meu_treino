package com.meutreino.exercise;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.meutreino.exercise.dto.CatalogDtos.CatalogDto;
import com.meutreino.exercise.dto.CatalogDtos.CategoryDto;
import com.meutreino.exercise.dto.CatalogDtos.EquipmentDto;
import com.meutreino.exercise.dto.CatalogDtos.MuscleDto;

/**
 * Catalogo base (musculos, equipamentos, categorias) mantido em memoria.
 * Sao poucas dezenas de registros e usados em praticamente toda resposta.
 */
@Service
public class CatalogService {

    private final MuscleRepository muscleRepository;
    private final EquipmentRepository equipmentRepository;
    private final ExerciseCategoryRepository categoryRepository;
    private final ExerciseRepository exerciseRepository;

    private final Map<Integer, Muscle> muscles = new ConcurrentHashMap<>();
    private final Map<Integer, Equipment> equipment = new ConcurrentHashMap<>();
    private final Map<Integer, ExerciseCategory> categories = new ConcurrentHashMap<>();

    public CatalogService(MuscleRepository muscleRepository,
                          EquipmentRepository equipmentRepository,
                          ExerciseCategoryRepository categoryRepository,
                          ExerciseRepository exerciseRepository) {
        this.muscleRepository = muscleRepository;
        this.equipmentRepository = equipmentRepository;
        this.categoryRepository = categoryRepository;
        this.exerciseRepository = exerciseRepository;
    }

    @Transactional(readOnly = true)
    public synchronized void reload() {
        muscles.clear();
        equipment.clear();
        categories.clear();
        muscleRepository.findAll().forEach(m -> muscles.put(m.getId(), m));
        equipmentRepository.findAll().forEach(e -> equipment.put(e.getId(), e));
        categoryRepository.findAll().forEach(c -> categories.put(c.getId(), c));
    }

    public Muscle muscle(Integer id) {
        if (muscles.isEmpty()) {
            reload();
        }
        return muscles.get(id);
    }

    public Equipment equipment(Integer id) {
        if (equipment.isEmpty()) {
            reload();
        }
        return equipment.get(id);
    }

    public ExerciseCategory category(Integer id) {
        if (categories.isEmpty()) {
            reload();
        }
        return categories.get(id);
    }

    public MuscleDto toDto(Muscle muscle) {
        if (muscle == null) {
            return null;
        }
        return new MuscleDto(muscle.getId(), muscle.displayName(), muscle.getName(), muscle.isFront(),
                muscle.getImageUrlMain());
    }

    public MuscleDto muscleDto(Integer id) {
        return toDto(muscle(id));
    }

    public String muscleName(Integer id) {
        Muscle m = muscle(id);
        return m == null ? null : m.displayName();
    }

    @Transactional(readOnly = true)
    public CatalogDto catalog() {
        if (muscles.isEmpty()) {
            reload();
        }
        List<MuscleDto> muscleDtos = muscles.values().stream()
                .sorted(Comparator.comparing(Muscle::displayName))
                .map(this::toDto)
                .collect(Collectors.toList());
        List<EquipmentDto> equipmentDtos = equipment.values().stream()
                .sorted(Comparator.comparing(Equipment::displayName))
                .map(e -> new EquipmentDto(e.getId(), e.displayName()))
                .collect(Collectors.toList());
        List<CategoryDto> categoryDtos = categories.values().stream()
                .sorted(Comparator.comparing(ExerciseCategory::displayName))
                .map(c -> new CategoryDto(c.getId(), c.displayName()))
                .collect(Collectors.toList());
        return new CatalogDto(muscleDtos, equipmentDtos, categoryDtos, exerciseRepository.count());
    }
}

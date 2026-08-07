package com.meutreino.workout;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * Modelos de divisao de treino prontos.
 *
 * <p>Cada slot referencia nomes de exercicios do catalogo (em ingles, como vem do
 * wger) em ordem de preferencia. Se nenhum for encontrado, o servico cai para uma
 * busca por categoria.
 */
public final class SplitTemplates {

    private SplitTemplates() {
    }

    public record Slot(List<String> preferredNames, Integer categoryId, int sets, String reps, int rest) {
    }

    public record Day(String label, String name, List<Slot> slots) {
    }

    public record Template(String code, String name, String description, List<Day> days) {
    }

    // categorias do wger
    private static final int ARMS = 8;
    private static final int LEGS = 9;
    private static final int ABS = 10;
    private static final int CHEST = 11;
    private static final int BACK = 12;
    private static final int SHOULDERS = 13;
    private static final int CALVES = 14;

    private static Slot slot(int sets, String reps, int rest, int categoryId, String... names) {
        return new Slot(List.of(names), categoryId, sets, reps, rest);
    }

    // --------------------------- blocos reutilizaveis ---------------------------

    private static List<Slot> chestBlock() {
        return List.of(
                slot(4, "8-10", 120, CHEST, "Bench Press"),
                slot(3, "10-12", 90, CHEST, "Incline Bench Press - MP", "Chest Press", "Dumbbell Bench Press"),
                slot(3, "12-15", 60, CHEST, "Butterfly", "Pec Deck", "Machine chest fly"),
                slot(3, "10-12", 60, CHEST, "Push-Up", "Dips"));
    }

    private static List<Slot> tricepsBlock() {
        return List.of(
                slot(3, "10-12", 60, ARMS, "Triceps Pushdown", "Cable Triceps Press"),
                slot(3, "10-12", 60, ARMS, "Skullcrusher SZ-bar", "Overhead Triceps Extension"));
    }

    private static List<Slot> backBlock() {
        return List.of(
                slot(4, "8-10", 120, BACK, "Pull-ups", "Assisted Pull-Up", "Underhand Lat Pull Down"),
                slot(4, "10-12", 90, BACK, "Bent Over Rowing", "Seated Cable Row", "Seated Row (Machine)"),
                slot(3, "10-12", 90, BACK, "Underhand Lat Pull Down", "V-Bar Pulldown"),
                slot(3, "12-15", 60, BACK, "Pullover", "Low row"));
    }

    private static List<Slot> bicepsBlock() {
        return List.of(
                slot(3, "10-12", 60, ARMS, "Biceps Curls With Dumbbell", "Cable Curls", "Biceps Curl Machine"),
                slot(3, "10-12", 60, ARMS, "Hammer Curls", "Preacher Curls"));
    }

    private static List<Slot> legsBlock() {
        return List.of(
                slot(4, "8-10", 150, LEGS, "Squats", "Hack Squats"),
                slot(4, "10-12", 120, LEGS, "Leg Press"),
                slot(3, "12-15", 60, LEGS, "Leg Extension"),
                slot(3, "12-15", 60, LEGS, "Leg Curl", "Leg Curls (laying)"),
                slot(3, "10-12", 90, LEGS, "Romanian Deadlift", "Stiff-legged Deadlifts"),
                slot(4, "15-20", 45, CALVES, "Standing Calf Raises", "Sitting Calf Raises"));
    }

    private static List<Slot> shouldersBlock() {
        return List.of(
                slot(4, "8-10", 120, SHOULDERS, "Overhead Press", "Arnold Shoulder Press"),
                slot(4, "12-15", 60, SHOULDERS, "Lateral Raises"),
                slot(3, "12-15", 60, SHOULDERS, "Front Raises"),
                slot(3, "12-15", 60, SHOULDERS, "Rear Delt Raises", "Reverse Fly Standing"),
                slot(3, "12-15", 60, BACK, "Shoulder Shrug", "Shrugs, Barbells"));
    }

    private static List<Slot> absBlock() {
        return List.of(
                slot(3, "15-20", 45, ABS, "Crunches", "Abdominal Crunch"),
                slot(3, "12-15", 45, ABS, "Leg Raise", "Hanging Leg Raises"),
                slot(3, "40s", 45, ABS, "Plank"));
    }

    private static List<Slot> join(List<Slot>... blocks) {
        return java.util.Arrays.stream(blocks).flatMap(List::stream).toList();
    }

    // ------------------------------- templates --------------------------------

    private static final Map<String, Template> TEMPLATES = new LinkedHashMap<>();

    static {
        register(new Template("ABC", "ABC", "Tres treinos: peito/triceps, costas/biceps, pernas/ombros", List.of(
                new Day("A", "Peito e Triceps", join(chestBlock(), tricepsBlock())),
                new Day("B", "Costas e Biceps", join(backBlock(), bicepsBlock())),
                new Day("C", "Pernas e Ombros", join(legsBlock(), shouldersBlock().subList(0, 3))))));

        register(new Template("ABCD", "ABCD", "Quatro treinos: peito/triceps, costas/biceps, pernas, ombros/abdomen",
                List.of(
                        new Day("A", "Peito e Triceps", join(chestBlock(), tricepsBlock())),
                        new Day("B", "Costas e Biceps", join(backBlock(), bicepsBlock())),
                        new Day("C", "Pernas", legsBlock()),
                        new Day("D", "Ombros e Abdomen", join(shouldersBlock(), absBlock())))));

        register(new Template("ABCDE", "ABCDE", "Cinco treinos: peito, costas, pernas, ombros, bracos", List.of(
                new Day("A", "Peito", join(chestBlock(), absBlock().subList(0, 2))),
                new Day("B", "Costas", backBlock()),
                new Day("C", "Pernas", legsBlock()),
                new Day("D", "Ombros", shouldersBlock()),
                new Day("E", "Bracos", join(bicepsBlock(), tricepsBlock(), absBlock().subList(0, 2))))));

        register(new Template("PPL", "Push Pull Legs", "Empurrar, puxar e pernas", List.of(
                new Day("PUSH", "Push - Peito, Ombro e Triceps",
                        join(chestBlock().subList(0, 3), shouldersBlock().subList(0, 3), tricepsBlock())),
                new Day("PULL", "Pull - Costas e Biceps", join(backBlock(), bicepsBlock())),
                new Day("LEGS", "Legs - Pernas e Abdomen", join(legsBlock(), absBlock().subList(0, 2))))));

        register(new Template("UPPER_LOWER", "Upper Lower", "Superiores e inferiores alternados", List.of(
                new Day("UPPER", "Upper - Superiores", join(
                        chestBlock().subList(0, 2),
                        backBlock().subList(0, 2),
                        shouldersBlock().subList(0, 2),
                        bicepsBlock().subList(0, 1),
                        tricepsBlock().subList(0, 1))),
                new Day("LOWER", "Lower - Inferiores", join(legsBlock(), absBlock().subList(0, 2))))));

        register(new Template("FULL_BODY", "Full Body", "Corpo inteiro em um unico treino", List.of(
                new Day("FB", "Full Body", join(
                        List.of(slot(4, "8-10", 150, LEGS, "Squats")),
                        chestBlock().subList(0, 2),
                        backBlock().subList(0, 2),
                        shouldersBlock().subList(1, 2),
                        bicepsBlock().subList(0, 1),
                        tricepsBlock().subList(0, 1),
                        absBlock().subList(0, 2))))));
    }

    private static void register(Template template) {
        TEMPLATES.put(template.code(), template);
    }

    public static Template get(String code) {
        return TEMPLATES.get(code == null ? "" : code.toUpperCase());
    }

    public static List<Template> all() {
        return List.copyOf(TEMPLATES.values());
    }
}

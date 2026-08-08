import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_effects.dart';
import 'app_themes.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// Converte um [ThemeDefinition] em [ThemeData].
///
/// Toda a aparência dos componentes Material é definida aqui a partir dos
/// tokens. Assim, um card ou botão sem estilo explícito já nasce coerente com
/// o design system, e trocar de tema não exige tocar em nenhuma tela.
class ThemeBuilder {
  const ThemeBuilder._();

  static ThemeData build(ThemeDefinition definition) {
    final t = definition.tokens;
    final text = _applyColors(AppTypography.textTheme(), t);

    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: t.primary,
      onPrimary: t.onPrimary,
      primaryContainer: t.primarySoft,
      onPrimaryContainer: t.primary,
      secondary: t.secondary,
      onSecondary: t.onPrimary,
      secondaryContainer: t.secondary.withValues(alpha: 0.16),
      onSecondaryContainer: t.secondary,
      tertiary: t.accent,
      onTertiary: t.onPrimary,
      tertiaryContainer: t.accent.withValues(alpha: 0.16),
      onTertiaryContainer: t.accent,
      error: t.error,
      onError: t.onPrimary,
      errorContainer: t.error.withValues(alpha: 0.16),
      onErrorContainer: t.error,
      surface: t.surface,
      onSurface: t.textPrimary,
      surfaceContainerLowest: t.background,
      surfaceContainerLow: t.surfaceSunken,
      surfaceContainer: t.surface,
      surfaceContainerHigh: t.surfaceElevated,
      surfaceContainerHighest: t.surfaceElevated,
      onSurfaceVariant: t.textSecondary,
      outline: t.border,
      outlineVariant: t.border,
      shadow: const Color(0xFF000000),
      scrim: t.scrim,
      inverseSurface: t.textPrimary,
      onInverseSurface: t.background,
      inversePrimary: t.primaryVariant,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: t.background,
      canvasColor: t.background,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: text,
      primaryTextTheme: text,
      extensions: [t],

      // -------------------------------- app bar ------------------------------
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: t.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 18,
        iconTheme: IconThemeData(color: t.textSecondary, size: 22),
        actionsIconTheme: IconThemeData(color: t.textSecondary, size: 22),
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      // ---------------------------------- card -------------------------------
      cardTheme: CardThemeData(
        color: t.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.lg),
          side: BorderSide(color: t.border),
        ),
      ),

      // --------------------------------- inputs ------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.surfaceSunken,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: text.bodyMedium?.copyWith(color: t.textMuted),
        labelStyle: text.bodyMedium?.copyWith(color: t.textSecondary),
        floatingLabelStyle: text.labelMedium?.copyWith(color: t.primary),
        helperStyle: text.bodySmall?.copyWith(color: t.textMuted),
        errorStyle: text.bodySmall?.copyWith(color: t.error),
        prefixIconColor: t.textMuted,
        suffixIconColor: t.textMuted,
        border: _inputBorder(t.border),
        enabledBorder: _inputBorder(t.border),
        focusedBorder: _inputBorder(t.primary, width: 1.4),
        errorBorder: _inputBorder(t.error),
        focusedErrorBorder: _inputBorder(t.error, width: 1.4),
        disabledBorder: _inputBorder(t.border.withValues(alpha: 0.5)),
      ),

      // -------------------------------- botões -------------------------------
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(54)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return t.primary.withValues(alpha: 0.28);
            }
            if (states.contains(WidgetState.pressed)) return t.primaryVariant;
            return t.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return t.onPrimary.withValues(alpha: 0.6);
            }
            return t.onPrimary;
          }),
          overlayColor: WidgetStatePropertyAll(t.onPrimary.withValues(alpha: 0.08)),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.all(AppRadius.md)),
          ),
          textStyle: WidgetStatePropertyAll(
            AppTypography.label(14.5, weight: FontWeight.w700),
          ),
          iconColor: WidgetStatePropertyAll(t.onPrimary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(52)),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return t.textMuted;
            return t.textPrimary;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return BorderSide(color: t.primary, width: 1.4);
            }
            return BorderSide(color: t.borderStrong);
          }),
          overlayColor: WidgetStatePropertyAll(t.primary.withValues(alpha: 0.08)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.all(AppRadius.md)),
          ),
          textStyle: WidgetStatePropertyAll(
            AppTypography.label(14, weight: FontWeight.w700),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(t.primary),
          overlayColor: WidgetStatePropertyAll(t.primary.withValues(alpha: 0.10)),
          textStyle: WidgetStatePropertyAll(
            AppTypography.label(13.5, weight: FontWeight.w700),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.all(AppRadius.sm)),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(t.textSecondary),
          overlayColor: WidgetStatePropertyAll(t.primary.withValues(alpha: 0.10)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.all(AppRadius.sm)),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: t.primary,
        foregroundColor: t.onPrimary,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        extendedTextStyle: AppTypography.label(14, weight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all(AppRadius.md)),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? t.primarySoft : Colors.transparent),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected) ? t.primary : t.textSecondary),
          side: WidgetStatePropertyAll(BorderSide(color: t.border)),
          textStyle: WidgetStatePropertyAll(AppTypography.label(13)),
        ),
      ),

      // --------------------------------- chips -------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: t.surfaceSunken,
        selectedColor: t.primarySoft,
        disabledColor: t.surfaceSunken,
        surfaceTintColor: Colors.transparent,
        checkmarkColor: t.primary,
        side: BorderSide(color: t.border),
        labelStyle: text.labelMedium?.copyWith(color: t.textSecondary),
        secondaryLabelStyle: text.labelMedium?.copyWith(color: t.primary),
        iconTheme: IconThemeData(color: t.textSecondary, size: 16),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all(AppRadius.sm)),
        showCheckmark: false,
      ),

      // ------------------------------ navegação ------------------------------
      navigationBarTheme: NavigationBarThemeData(
        height: 66,
        elevation: 0,
        backgroundColor: t.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        indicatorColor: t.primarySoft,
        indicatorShape: RoundedRectangleBorder(borderRadius: AppRadius.all(AppRadius.sm)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected) ? t.primary : t.textMuted,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.label(
            10.5,
            weight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
            color: states.contains(WidgetState.selected) ? t.primary : t.textMuted,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: t.primary,
        unselectedLabelColor: t.textMuted,
        labelStyle: AppTypography.label(13),
        unselectedLabelStyle: AppTypography.label(13, weight: FontWeight.w600),
        indicatorColor: t.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: t.border,
      ),

      // ---------------------------- listas e divisores -----------------------
      listTileTheme: ListTileThemeData(
        iconColor: t.textSecondary,
        textColor: t.textPrimary,
        titleTextStyle: text.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        subtitleTextStyle: text.bodySmall?.copyWith(color: t.textSecondary),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all(AppRadius.md)),
      ),
      dividerTheme: DividerThemeData(color: t.border, thickness: 1, space: 1),

      // ------------------------------- overlays ------------------------------
      dialogTheme: DialogThemeData(
        backgroundColor: t.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium?.copyWith(color: t.textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.lg),
          side: BorderSide(color: t.borderStrong),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: t.surfaceElevated,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: t.borderStrong,
        dragHandleSize: const Size(40, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          side: BorderSide(color: t.borderStrong),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: t.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        textStyle: text.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          side: BorderSide(color: t.borderStrong),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.surfaceElevated,
        contentTextStyle: text.bodyMedium?.copyWith(color: t.textPrimary),
        actionTextColor: t.primary,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.all(AppRadius.md),
          side: BorderSide(color: t.borderStrong),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: t.surfaceElevated,
          borderRadius: AppRadius.all(AppRadius.xs),
          border: Border.all(color: t.borderStrong),
        ),
        textStyle: text.bodySmall?.copyWith(color: t.textPrimary),
      ),

      // ------------------------------ indicadores ----------------------------
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: t.progress,
        linearTrackColor: t.track,
        circularTrackColor: t.track,
        linearMinHeight: 6,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: t.primary,
        inactiveTrackColor: t.track,
        thumbColor: t.primary,
        overlayColor: t.primary.withValues(alpha: 0.14),
        valueIndicatorColor: t.primary,
        valueIndicatorTextStyle: AppTypography.display(
          size: 13,
          weight: FontWeight.w700,
          color: t.onPrimary,
        ),
        trackHeight: 5,
        activeTickMarkColor: t.primary.withValues(alpha: 0.6),
        inactiveTickMarkColor: t.borderStrong,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? t.onPrimary : t.textMuted),
        trackColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? t.primary : t.surfaceSunken),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? t.primary : t.border),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? t.primary : Colors.transparent),
        checkColor: WidgetStatePropertyAll(t.onPrimary),
        side: BorderSide(color: t.borderStrong, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.all(AppRadius.xs)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? t.primary : t.borderStrong),
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: t.primary,
        textColor: t.onPrimary,
        textStyle: AppTypography.display(size: 10, weight: FontWeight.w800),
      ),
      iconTheme: IconThemeData(color: t.textSecondary, size: 22),
      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: text.bodyMedium,
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(t.surfaceElevated),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: AppRadius.all(AppRadius.md),
              side: BorderSide(color: t.borderStrong),
            ),
          ),
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(t.borderStrong),
        radius: const Radius.circular(4),
        thickness: const WidgetStatePropertyAll(4),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: t.primary,
        selectionColor: t.primary.withValues(alpha: 0.30),
        selectionHandleColor: t.primary,
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: AppRadius.all(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static TextTheme _applyColors(TextTheme base, AppTokens t) {
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(color: t.textPrimary),
      displayMedium: base.displayMedium?.copyWith(color: t.textPrimary),
      displaySmall: base.displaySmall?.copyWith(color: t.textPrimary),
      headlineLarge: base.headlineLarge?.copyWith(color: t.textPrimary),
      headlineMedium: base.headlineMedium?.copyWith(color: t.textPrimary),
      headlineSmall: base.headlineSmall?.copyWith(color: t.textPrimary),
      titleLarge: base.titleLarge?.copyWith(color: t.textPrimary),
      titleMedium: base.titleMedium?.copyWith(color: t.textPrimary),
      titleSmall: base.titleSmall?.copyWith(color: t.textPrimary),
      bodyLarge: base.bodyLarge?.copyWith(color: t.textPrimary),
      bodyMedium: base.bodyMedium?.copyWith(color: t.textPrimary),
      bodySmall: base.bodySmall?.copyWith(color: t.textSecondary),
      labelLarge: base.labelLarge?.copyWith(color: t.textPrimary),
      labelMedium: base.labelMedium?.copyWith(color: t.textSecondary),
      labelSmall: base.labelSmall?.copyWith(color: t.textMuted),
    );
  }
}

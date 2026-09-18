import 'package:flutter/material.dart';

/// Material 3 theme inspired by Huawei's "immersive light" design language:
/// layered surfaces, soft shadows and light that follows interaction.
class AppTheme {
  AppTheme._();

  static const Color huaweiBlue = Color(0xFF0A59F7);
  static const Color expenseRed = Color(0xFFE84026);
  static const Color incomeGreen = Color(0xFF1FA971);

  static const List<Color> lightGradient = [
    Color(0xFFF3F6FC),
    Color(0xFFEAF0FA),
    Color(0xFFF6F3FF),
  ];

  static const List<Color> darkGradient = [
    Color(0xFF0B0F1A),
    Color(0xFF111726),
    Color(0xFF171326),
  ];

  static List<Color> gradientFor(Brightness brightness) =>
      brightness == Brightness.dark ? darkGradient : lightGradient;

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: huaweiBlue,
      brightness: Brightness.light,
    ).copyWith(
      surface: const Color(0xFFF7F9FE),
      onSurface: const Color(0xFF182431),
      onSurfaceVariant: const Color(0xFF5E6675),
      outline: const Color(0xFF8C96A5),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF2F5FC),
      surfaceContainer: const Color(0xFFEDF1FA),
      surfaceContainerHigh: const Color(0xFFE7ECF7),
      surfaceContainerHighest: const Color(0xFFE1E7F4),
      outlineVariant: const Color(0xFFDCE2EE),
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: huaweiBlue,
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF10141F),
      onSurface: const Color(0xFFE9EEF7),
      onSurfaceVariant: const Color(0xFFA8B1C2),
      outline: const Color(0xFF7A8494),
      surfaceContainerLowest: const Color(0xFF0B0E16),
      surfaceContainerLow: const Color(0xFF141926),
      surfaceContainer: const Color(0xFF181E2C),
      surfaceContainerHigh: const Color(0xFF1E2534),
      surfaceContainerHighest: const Color(0xFF242C3D),
      outlineVariant: const Color(0xFF2C3446),
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final shadow = isDark ? Colors.black.withValues(alpha: 0.45) : const Color(0x14003366);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      // RootShell overrides this with a transparent scaffold so the gradient
      // shows through; pushed pages get this solid surface.
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: shadow,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: isDark ? 0.5 : 1.5,
        shadowColor: shadow,
        surfaceTintColor: Colors.transparent,
        color: scheme.surfaceContainerLowest,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          textStyle: const WidgetStatePropertyAll(
              TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          foregroundColor: WidgetStatePropertyAll(scheme.primary),
          side: WidgetStatePropertyAll(
              BorderSide(color: scheme.primary.withValues(alpha: 0.45))),
          textStyle: const WidgetStatePropertyAll(
              TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          foregroundColor: WidgetStatePropertyAll(scheme.primary),
          textStyle: const WidgetStatePropertyAll(
              TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: const WidgetStatePropertyAll(2),
          shadowColor: WidgetStatePropertyAll(shadow),
          minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          textStyle: const WidgetStatePropertyAll(
              TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          side: WidgetStatePropertyAll(BorderSide(color: scheme.outlineVariant)),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? scheme.primary
                : Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? scheme.onPrimary
                : scheme.onSurfaceVariant;
          }),
          textStyle: const WidgetStatePropertyAll(
              TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          padding: const WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) => states
                .contains(WidgetState.selected)
            ? Colors.white
            : scheme.outline),
        trackColor: WidgetStateProperty.resolveWith((states) => states
                .contains(WidgetState.selected)
            ? scheme.primary
            : scheme.surfaceContainerHighest),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        shadowColor: shadow,
        height: 68,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 4,
        highlightElevation: 8,
        shape: const StadiumBorder(),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(scheme.onSurface),
          shape: const WidgetStatePropertyAll(CircleBorder()),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.7),
        thickness: 0.6,
        space: 0.6,
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide(color: scheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: scheme.onSurface,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: scheme.onSecondaryContainer,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: scheme.surfaceContainerHigh.withValues(alpha: 0.6),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ImmersivePageTransitionsBuilder(),
          TargetPlatform.iOS: ImmersivePageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Fade + slide + subtle scale transition used for pushed pages.
class ImmersivePageTransitionsBuilder extends PageTransitionsBuilder {
  const ImmersivePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
          child: child,
        ),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:palette_generator/palette_generator.dart';
import '/utils/helper.dart';
import '/ui/theme/app_colors.dart';
import '/ui/theme/app_typography.dart';

class ThemeController extends GetxController {
  final primaryColor = const Color(0xFF6C63FF).obs;
  final textColor = Colors.white.obs;
  final themedata = Rxn<ThemeData>();

  final platform = const MethodChannel('win_titlebar_color');
  String? currentSongId;
  late Brightness systemBrightness;

  ThemeController() {
    systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;

    // Read stored seed color (falls back to violet)
    final storedColor = Hive.box('appPrefs').get("themePrimaryColor");
    if (storedColor != null) {
      primaryColor.value = Color(storedColor as int);
    }

    changeThemeModeType(
        ThemeType.values[Hive.box('appPrefs').get("themeModeType") ?? 0]);

    _listenSystemBrightness();
    super.onInit();
  }

  void _listenSystemBrightness() {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    dispatcher.onPlatformBrightnessChanged = () {
      systemBrightness = dispatcher.platformBrightness;
      changeThemeModeType(
          ThemeType.values[Hive.box('appPrefs').get("themeModeType")],
          sysCall: true);
    };
  }

  void changeThemeModeType(dynamic value, {bool sysCall = false}) {
    if (value == ThemeType.system) {
      themedata.value = _buildThemeData(
          primaryColor.value,
          systemBrightness == Brightness.light
              ? ThemeType.light
              : ThemeType.dark);
    } else {
      if (sysCall) return;
      themedata.value = _buildThemeData(primaryColor.value, value);
    }
    setWindowsTitleBarColor(themedata.value!.scaffoldBackgroundColor);
  }

  /// Called from player when a new song starts — extracts dominant color
  /// and rebuilds the dynamic theme.
  void setTheme(ImageProvider imageProvider, String songId) async {
    if (songId == currentSongId) return;
    PaletteGenerator generator = await PaletteGenerator.fromImageProvider(
        ResizeImage(imageProvider, height: 200, width: 200));

    final paletteColor = generator.dominantColor ??
        generator.darkMutedColor ??
        generator.darkVibrantColor ??
        generator.lightMutedColor ??
        generator.lightVibrantColor;

    if (paletteColor == null) return;

    Color seed = paletteColor.color;
    textColor.value = paletteColor.bodyTextColor;

    // Keep seed dark enough for the dark glass aesthetic
    if (seed.computeLuminance() > 0.12) {
      seed = HSLColor.fromColor(seed).withLightness(0.12).toColor();
    }

    primaryColor.value = seed;
    themedata.value = _buildThemeData(seed, ThemeType.dynamic);
    currentSongId = songId;

    Hive.box('appPrefs').put("themePrimaryColor", primaryColor.value.value);
    setWindowsTitleBarColor(themedata.value!.scaffoldBackgroundColor);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Theme builder — Material 3 enabled for all modes
  // ─────────────────────────────────────────────────────────────────────────

  ThemeData _buildThemeData(Color seedColor, ThemeType type) {
    final isDark = type == ThemeType.dark || type == ThemeType.dynamic;
    final brightness = isDark ? Brightness.dark : Brightness.light;

    _applySystemUiOverlay(isDark);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
    ).copyWith(
      surface: isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
      onSurface:
          isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      surfaceContainer:
          isDark ? AppColors.darkSurface : AppColors.lightSurface,
      surfaceContainerHigh:
          isDark ? AppColors.darkCard : AppColors.lightCard,
      surfaceContainerHighest:
          isDark ? AppColors.darkElevated : AppColors.lightCard,
    );

    final textTheme =
        isDark ? AppTypography.darkTextTheme : AppTypography.lightTextTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkScaffold : AppColors.lightScaffold,
      canvasColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      cardColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      // ── Bottom Sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            isDark ? AppColors.darkSurface : AppColors.lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        modalBarrierColor: Colors.black.withOpacity(0.45),
      ),
      // ── Navigation Bar ────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colorScheme.primary.withOpacity(0.25),
        labelTextStyle: WidgetStateProperty.all(
          textTheme.labelMedium?.copyWith(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
              size: 24,
            );
          }
          return IconThemeData(
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textSecondaryLight,
            size: 24,
          );
        }),
      ),
      // ── Navigation Rail ───────────────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: colorScheme.primary.withOpacity(0.2),
        selectedIconTheme: const IconThemeData(color: Colors.white, size: 24),
        unselectedIconTheme: IconThemeData(
            color: isDark
                ? AppColors.textTertiaryDark
                : AppColors.textSecondaryLight,
            size: 22),
        selectedLabelTextStyle: TextStyle(
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textSecondaryLight,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
      // ── Slider ────────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        inactiveTrackColor:
            isDark ? Colors.white.withOpacity(0.15) : Colors.black26,
        activeTrackColor: colorScheme.primary,
        secondaryActiveTrackColor: colorScheme.primary.withOpacity(0.3),
        thumbColor: Colors.white,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        valueIndicatorColor: colorScheme.primary,
        trackHeight: 3.5,
      ),
      // ── Progress Indicator ────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor:
            isDark ? Colors.white.withOpacity(0.12) : Colors.black12,
      ),
      // ── Input / Text Field ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        hintStyle: TextStyle(
            color: isDark ? AppColors.textTertiaryDark : Colors.black38),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withOpacity(0.3),
        selectionHandleColor: colorScheme.primary,
      ),
      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor:
            isDark ? AppColors.darkCard : AppColors.lightCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      // ── Icon ─────────────────────────────────────────────────────────────
      iconTheme: IconThemeData(
          color:
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color:
            isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
        thickness: 1,
        space: 1,
      ),
    );
  }

  void _applySystemUiOverlay(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  Future<void> setWindowsTitleBarColor(Color color) async {
    if (!GetPlatform.isWindows) return;
    try {
      Future.delayed(
          const Duration(milliseconds: 350),
          () async => await platform.invokeMethod('setTitleBarColor', {
                'r': color.red,
                'g': color.green,
                'b': color.blue,
              }));
    } on PlatformException catch (e) {
      printERROR("Failed to set title bar color: ${e.message}");
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Color Extensions — kept for backwards compatibility with other files
// ─────────────────────────────────────────────────────────────────────────────

extension ColorWithHSL on Color {
  HSLColor get hsl => HSLColor.fromColor(this);

  Color withSaturation(double saturation) =>
      hsl.withSaturation(clampDouble(saturation, 0.0, 1.0)).toColor();

  Color withLightness(double lightness) =>
      hsl.withLightness(clampDouble(lightness, 0.0, 1.0)).toColor();

  Color withHue(double hue) =>
      hsl.withHue(clampDouble(hue, 0.0, 360.0)).toColor();
}

extension ComplementaryColor on Color {
  Color get complementaryColor => getComplementaryColor(this);
  Color getComplementaryColor(Color color) {
    return Color.fromARGB(
        color.alpha, 255 - color.red, 255 - color.green, 255 - color.blue);
  }
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String toHex({bool leadingHashSign = true}) =>
      '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';
}

enum ThemeType {
  dynamic,
  system,
  dark,
  light,
}

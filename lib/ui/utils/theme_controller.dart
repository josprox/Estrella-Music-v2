import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:palette_generator/palette_generator.dart';
import '/utils/helper.dart';

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
    final storedColor = Hive.box('AppPrefs').get("themePrimaryColor");
    if (storedColor != null) {
      primaryColor.value = Color(storedColor as int);
    }

    changeThemeModeType(
        ThemeType.values[Hive.box('AppPrefs').get("themeModeType") ?? 0]);

    _listenSystemBrightness();
    super.onInit();
  }

  void _listenSystemBrightness() {
    final dispatcher = WidgetsBinding.instance.platformDispatcher;
    dispatcher.onPlatformBrightnessChanged = () {
      systemBrightness = dispatcher.platformBrightness;
      changeThemeModeType(
          ThemeType.values[Hive.box('AppPrefs').get("themeModeType")],
          sysCall: true);
    };
  }

  void changeThemeModeType(dynamic value, {bool sysCall = false, ColorScheme? dynamicColors}) {
    final themeType = value is ThemeType ? value : ThemeType.values[value ?? 0];
    
    // Determine brightness
    Brightness brightness;
    if (themeType == ThemeType.system || themeType == ThemeType.dynamic) {
      brightness = systemBrightness;
    } else {
      brightness = themeType == ThemeType.light ? Brightness.light : Brightness.dark;
    }

    // Prioritize song's dominant color palette (primaryColor) over system dynamic colors when a song is active
    final finalDynamicColors = (currentSongId != null) ? null : dynamicColors;

    themedata.value = _buildThemeData(
      primaryColor.value, 
      brightness, 
      dynamicColors: finalDynamicColors
    );
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

    // Adjust seed for visibility if necessary, but keep it mostly true to the art
    primaryColor.value = seed;
    
    final type = ThemeType.values[Hive.box('AppPrefs').get("themeModeType") ?? 0];
    Brightness brightness;
    if (type == ThemeType.light) {
      brightness = Brightness.light;
    } else if (type == ThemeType.dark) {
      brightness = Brightness.dark;
    } else {
      // dynamic or system → follow the actual system brightness
      brightness = systemBrightness;
    }

    themedata.value = _buildThemeData(seed, brightness);
    currentSongId = songId;

    Hive.box('AppPrefs').put("themePrimaryColor", primaryColor.value.toARGB32());
    setWindowsTitleBarColor(themedata.value!.scaffoldBackgroundColor);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Theme builder — Material 3 enabled for all modes
  // ─────────────────────────────────────────────────────────────────────────

  ThemeData _buildThemeData(Color seedColor, Brightness brightness, {ColorScheme? dynamicColors}) {
    final isDark = brightness == Brightness.dark;
    _applySystemUiOverlay(isDark);

    ColorScheme colorScheme;
    if (dynamicColors != null) {
      colorScheme = dynamicColors;
    } else {
      colorScheme = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
        dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
      );
    }

    // Material 3 typography
    final textTheme = Typography.material2021(platform: defaultTargetPlatform)
        .black
        .apply(displayColor: colorScheme.onSurface, bodyColor: colorScheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      canvasColor: colorScheme.surface,
      cardColor: colorScheme.surfaceContainerHigh,
      
      // ── Bottom Sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        modalBarrierColor: Colors.black.withValues(alpha: 0.45),
      ),

      // ── Navigation Bar ────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 0,
        indicatorColor: colorScheme.secondaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            );
          }
          return TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: colorScheme.onSecondaryContainer,
              size: 24,
            );
          }
          return IconThemeData(
            color: colorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
      ),

      // ── Navigation Rail ───────────────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        indicatorColor: colorScheme.secondaryContainer,
        selectedIconTheme: IconThemeData(color: colorScheme.onSecondaryContainer, size: 24),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant, size: 22),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
        unselectedLabelTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),

      // ── Slider ────────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.15),
        activeTrackColor: colorScheme.primary,
        secondaryActiveTrackColor: colorScheme.primary.withValues(alpha: 0.3),
        thumbColor: colorScheme.primary,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
        valueIndicatorColor: colorScheme.primary,
        trackHeight: 4,
      ),

      // ── Progress Indicator ────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.onSurface.withValues(alpha: 0.12),
      ),

      // ── Input / Text Field ────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primary.withValues(alpha: 0.3),
        selectionHandleColor: colorScheme.primary,
      ),

      // ── Dialog ───────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),

      // ── Icon ─────────────────────────────────────────────────────────────
      iconTheme: IconThemeData(color: colorScheme.onSurface),

      // ── FAB ──────────────────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }

  void _applySystemUiOverlay(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
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
                'r': (color.r * 255).round().clamp(0, 255),
                'g': (color.g * 255).round().clamp(0, 255),
                'b': (color.b * 255).round().clamp(0, 255),
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
    return Color.from(
        alpha: color.a,
        red: 1.0 - color.r,
        green: 1.0 - color.g,
        blue: 1.0 - color.b);
  }
}

extension HexColor on Color {
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${(a * 255).round().toRadixString(16).padLeft(2, '0')}'
      '${(r * 255).round().toRadixString(16).padLeft(2, '0')}'
      '${(g * 255).round().toRadixString(16).padLeft(2, '0')}'
      '${(b * 255).round().toRadixString(16).padLeft(2, '0')}';
}

enum ThemeType {
  dynamic,
  system,
  dark,
  light,
}

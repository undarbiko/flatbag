import 'package:window_manager/window_manager.dart';
import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'models/app_settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  AppSettings settings = await AppSettings.load();
  AppTheme.themeMode.value = AppTheme.parseThemeMode(settings.themeMode);
  AppTheme.seedColor.value = Color(settings.accentColor);
  AppTheme.textScale.value = settings.textScale;
  Size initialSize = const Size(1000, 700);
  if (settings.persistWindowSize && settings.windowWidth != null && settings.windowHeight != null) {
    initialSize = Size(settings.windowWidth!, settings.windowHeight!);
  }

  WindowOptions windowOptions = WindowOptions(
    size: initialSize,
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden, // Ensures native OS window controls remain visible while hiding the default title bar.
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.setIcon('icons/flat_bag_128.png');
    await windowManager.setMinimumSize(Size(900 + (settings.textScale - 1.0) * 300, 650 + (settings.textScale - 1.0) * 300));
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Color>(
      valueListenable: AppTheme.seedColor,
      builder: (context, seedColor, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: AppTheme.themeMode,
          builder: (context, themeMode, _) {
            return ValueListenableBuilder<double>(
              valueListenable: AppTheme.textScale,
              builder: (context, textScale, _) {
                ThemeData defaultLight = ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.light),
                  dialogTheme: DialogThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 1.0),
                    ),
                  ),
                  extensions: const [
                    SemanticColors(successButton: Color(0xFF7AE190), infoButton: Color(0xFF86B0FF), warningButton: Color(0xFFFF994A)),
                  ],
                );
                ThemeData defaultDark = ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: seedColor, brightness: Brightness.dark),
                  dialogTheme: DialogThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1.0),
                    ),
                  ),
                  extensions: const [
                    SemanticColors(
                      // Using slightly muted/darker pastel colors for dark mode to reduce eye strain
                      // while maintaining the same hue as the light theme.
                      successButton: Color(0xFF5BAA6C),
                      infoButton: Color(0xFF6586C2),
                      warningButton: Color(0xFFCC7B3A),
                    ),
                  ],
                );

                ThemeData activeLight = defaultLight;
                ThemeData activeDark = defaultDark;

                if (themeMode == ThemeMode.light) {
                  // Brighten the accent color slightly for the pure Light theme
                  Color lighterSeed = Color.lerp(seedColor, Colors.white, 0.2) ?? seedColor;
                  activeLight = defaultLight.copyWith(
                    colorScheme: ColorScheme.fromSeed(seedColor: lighterSeed, brightness: Brightness.light).copyWith(
                      surface: Colors.white,
                      surfaceTint: Colors.transparent, // Removes the Material 3 color wash
                    ),
                    scaffoldBackgroundColor: Colors.white,
                    cardTheme: const CardThemeData(
                      color: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      elevation: 2, // Slight shadow to separate from white background
                    ),
                    dialogTheme: DialogThemeData(
                      backgroundColor: Colors.white,
                      surfaceTintColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        side: BorderSide(color: Colors.black.withValues(alpha: 0.1), width: 1.0),
                      ),
                    ),
                  );
                } else if (themeMode == ThemeMode.dark) {
                  activeDark = defaultDark.copyWith(
                    colorScheme: defaultDark.colorScheme.copyWith(surface: const Color(0xFF1E1E1E)),
                    scaffoldBackgroundColor: const Color(0xFF121212),
                  );
                }

                return MaterialApp(
                  title: 'FlatBag',
                  debugShowCheckedModeBanner: false,
                  themeMode: themeMode,
                  theme: activeLight,
                  darkTheme: activeDark,
                  builder: (context, child) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
                      child: child!,
                    );
                  },
                  home: const MyHomePage(title: 'FlatBag'),
                );
              },
            );
          },
        );
      },
    );
  }
}

/// Custom semantic colors that are not part of the standard Material ColorScheme.
class SemanticColors extends ThemeExtension<SemanticColors> {
  final Color successButton;
  final Color infoButton;
  final Color warningButton;

  const SemanticColors({required this.successButton, required this.infoButton, required this.warningButton});

  @override
  ThemeExtension<SemanticColors> copyWith({Color? successButton, Color? infoButton, Color? warningButton}) {
    return SemanticColors(
      successButton: successButton ?? this.successButton,
      infoButton: infoButton ?? this.infoButton,
      warningButton: warningButton ?? this.warningButton,
    );
  }

  @override
  ThemeExtension<SemanticColors> lerp(covariant ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      successButton: Color.lerp(successButton, other.successButton, t)!,
      infoButton: Color.lerp(infoButton, other.infoButton, t)!,
      warningButton: Color.lerp(warningButton, other.warningButton, t)!,
    );
  }
}

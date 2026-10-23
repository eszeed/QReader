import 'package:flutter/material.dart';
import 'package:rss_reader/ui/Home.dart';
import 'package:rss_reader/data/theme_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final initialTheme = await ThemePreferences.loadThemeMode();
  runApp(MyApp(initialTheme: initialTheme));
}

class MyApp extends StatefulWidget {
  final ThemeMode initialTheme;

  const MyApp({super.key, required this.initialTheme});

  /// 全局主题模式通知器，可在其他页面中更新主题
  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(
    ThemeMode.system,
  );

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    MyApp.themeNotifier.value = widget.initialTheme;
  }

  @override
  void dispose() {
    MyApp.themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: MyApp.themeNotifier,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'QReader',
          theme: ThemeData(
            useMaterial3: true,
            // 全局字体
            fontFamily: 'Harmony',
            // 颜色主题
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            // AppBar 样式
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
            // Card 样式
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            // 全局字体
            fontFamily: 'Harmony',
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          themeMode: themeMode,
          home: Home(),
          // 隐藏调试标签
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

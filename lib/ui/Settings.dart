import 'package:flutter/material.dart';
import 'package:rss_reader/data/theme_preferences.dart';
import 'package:rss_reader/main.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _Settings();
}

class _Settings extends State<Settings> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final mode = await ThemePreferences.loadThemeMode();
    setState(() {
      _themeMode = mode;
    });
  }

  void _onThemeModeChanged(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    ThemePreferences.saveThemeMode(mode);
    MyApp.themeNotifier.value = mode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 主题模式设置
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '显示设置',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ThemeOption(
                    title: '跟随系统',
                    subtitle: '根据系统设置自动切换',
                    icon: Icons.brightness_auto,
                    value: ThemeMode.system,
                    groupValue: _themeMode,
                    onChanged: _onThemeModeChanged,
                  ),
                  _ThemeOption(
                    title: '明亮模式',
                    subtitle: '始终使用浅色主题',
                    icon: Icons.light_mode,
                    value: ThemeMode.light,
                    groupValue: _themeMode,
                    onChanged: _onThemeModeChanged,
                  ),
                  _ThemeOption(
                    title: '黑暗模式',
                    subtitle: '始终使用深色主题',
                    icon: Icons.dark_mode,
                    value: ThemeMode.dark,
                    groupValue: _themeMode,
                    onChanged: _onThemeModeChanged,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      title: Text(title),
      subtitle: Text(subtitle),
      secondary: Icon(icon),
      value: value,
      groupValue: groupValue,
      onChanged: (mode) {
        if (mode != null) {
          onChanged(mode);
        }
      },
      contentPadding: EdgeInsets.zero,
    );
  }
}

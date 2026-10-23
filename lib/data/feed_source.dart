import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class FeedSource {
  String name;
  String url;

  FeedSource({required this.name, required this.url});

  Map<String, dynamic> toJson() => {'name': name, 'url': url};

  factory FeedSource.fromJson(Map<String, dynamic> json) =>
      FeedSource(name: json['name'] as String, url: json['url'] as String);
}

const _kFeedSourcesKey = 'feed_sources';

// 默认订阅源
final List<FeedSource> defaultFeedSources = [
  FeedSource(name: '少数派', url: 'https://sspai.com/feed'),
];

/// 从 SharedPreferences 加载订阅源列表
Future<List<FeedSource>> loadFeedSources() async {
  final prefs = await SharedPreferences.getInstance();
  final jsonStr = prefs.getString(_kFeedSourcesKey);
  if (jsonStr == null || jsonStr.isEmpty) {
    // 首次使用，写入默认订阅源并返回
    await saveFeedSources(defaultFeedSources);
    return List.from(defaultFeedSources);
  }
  final List<dynamic> decoded = json.decode(jsonStr);
  return decoded
      .map((e) => FeedSource.fromJson(e as Map<String, dynamic>))
      .toList();
}

/// 保存订阅源列表到 SharedPreferences
Future<void> saveFeedSources(List<FeedSource> sources) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonStr = json.encode(sources.map((s) => s.toJson()).toList());
  await prefs.setString(_kFeedSourcesKey, jsonStr);
}

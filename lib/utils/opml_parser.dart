import 'package:rss_reader/data/feed_source.dart';
import 'package:xml/xml.dart';

/// 从 OPML XML 内容中解析出所有订阅源
///
/// 支持嵌套 outline（分类包含订阅源）和扁平 outline 两种格式。
/// 只提取带有 xmlUrl 属性的 outline 节点作为有效订阅源。
List<FeedSource> parseOpml(String xmlContent) {
  final document = XmlDocument.parse(xmlContent);
  final feeds = <FeedSource>[];
  final seenUrls = <String>{};

  // 递归遍历所有 outline 节点
  void visitOutline(XmlElement element) {
    final xmlUrl = element.getAttribute('xmlUrl')?.trim();
    if (xmlUrl != null && xmlUrl.isNotEmpty) {
      // 去重：同一 URL 只保留第一次出现的
      if (seenUrls.add(xmlUrl)) {
        // 优先使用 title，其次 text，最后 xmlUrl 本身
        final name = element.getAttribute('title')?.trim().isNotEmpty == true
            ? element.getAttribute('title')!.trim()
            : element.getAttribute('text')?.trim().isNotEmpty == true
                ? element.getAttribute('text')!.trim()
                : xmlUrl;
        feeds.add(FeedSource(name: name, url: xmlUrl));
      }
    }
    // 递归处理子 outline
    for (final child in element.findElements('outline')) {
      visitOutline(child);
    }
  }

  // 从 <body> 开始遍历
  final bodies = document.findAllElements('body');
  for (final body in bodies) {
    for (final outline in body.findElements('outline')) {
      visitOutline(outline);
    }
  }

  return feeds;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:rss_reader/utils/opml_parser.dart';

void main() {
  group('OPML Parser', () {
    test('解析空 OPML 返回空列表', () {
      final xml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
  </body>
</opml>''';
      final result = parseOpml(xml);
      expect(result, isEmpty);
    });

    test('解析基本订阅源', () {
      final xml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="Test Feed" xmlUrl="https://example.com/feed.xml"/>
  </body>
</opml>''';
      final result = parseOpml(xml);
      expect(result.length, 1);
      expect(result.first.url, 'https://example.com/feed.xml');
      expect(result.first.name, 'Test Feed');
    });

    test('解析嵌套分类订阅源', () {
      final xml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="Tech">
      <outline text="Feed A" xmlUrl="https://a.com/feed.xml"/>
      <outline text="Feed B" xmlUrl="https://b.com/feed.xml"/>
    </outline>
  </body>
</opml>''';
      final result = parseOpml(xml);
      expect(result.length, 2);
    });

    test('去重相同 URL', () {
      final xml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline text="Feed A" xmlUrl="https://a.com/feed.xml"/>
    <outline text="Feed A Dup" xmlUrl="https://a.com/feed.xml"/>
  </body>
</opml>''';
      final result = parseOpml(xml);
      expect(result.length, 1);
    });

    test('使用 title 属性作为名称', () {
      final xml = '''<?xml version="1.0" encoding="UTF-8"?>
<opml version="2.0">
  <body>
    <outline title="My Title" text="My Text" xmlUrl="https://a.com/feed.xml"/>
  </body>
</opml>''';
      final result = parseOpml(xml);
      expect(result.first.name, 'My Title');
    });
  });
}

import 'package:rss_reader/data/rss_item.dart';
import 'package:rss_reader/utils/xml_parser.dart';
import 'package:xml/xml.dart';

class rss_root {
  String title;

  String link;

  String description;

  String language;

  String managingEditor;

  String pubDate;

  List<rss_item> items = [];

  rss_root({
    required this.title,
    required this.link,
    required this.description,
    required this.language,
    required this.managingEditor,
    required this.pubDate,
    required this.items,
  });

  factory rss_root.fromXml(XmlDocument xml) {
    return rss_root(
      title: xml_parser.findElm(xml, "title").innerText,
      link: xml_parser.findElm(xml, "link").innerText,
      description: xml_parser.findElm(xml, "description").innerText,
      language: xml_parser.findElmOrNull(xml, "language")?.innerText ?? '',
      managingEditor:
          xml_parser.findElmOrNull(xml, "managingEditor")?.innerText ?? '',
      pubDate: xml_parser.findElmOrNull(xml, "pubDate")?.innerText ?? '',
      items: xml_parser
          .findElm(xml, "channel")
          .findElements("item")
          .map((e) => rss_item.fromXml(e))
          .toList(),
    );
  }

  @override
  String toString() {
    return 'rss_root{title: $title, link: $link, description: $description, language: $language, managingEditor: $managingEditor, pubDate: $pubDate, items: $items}';
  }
}

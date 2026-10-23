import 'package:xml/xml.dart';

import '../utils/xml_parser.dart';

class rss_item {
  String title;

  String link;

  String description;

  String author;

  String pubDate;

  String guid;

  rss_item({
    required this.title,
    required this.link,
    required this.description,
    required this.author,
    required this.pubDate,
    this.guid = '',
  });

  factory rss_item.fromXml(XmlElement xml) {
    return rss_item(
      title: xml_parser.find(xml, "title").innerText,
      link: xml_parser.find(xml, "link").innerText,
      description: xml_parser.find(xml, "description").innerText,
      author: xml_parser.findOrNull(xml, "author")?.innerText ?? '',
      pubDate: xml_parser.findOrNull(xml, "pubDate")?.innerText ?? '',
      guid: xml_parser.findOrNull(xml, "guid")?.innerText ?? '',
    );
  }

  @override
  String toString() {
    return 'rss_item{title: $title, link: $link, description: $description, author: $author, pubDate: $pubDate}';
  }
}

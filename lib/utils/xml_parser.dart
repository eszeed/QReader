import 'package:xml/xml.dart';

class xml_parser {
  static XmlElement findElm(XmlDocument document, String tag) {
    return document.findAllElements(tag).first;
  }

  /// 安全查找，不存在时返回 null
  static XmlElement? findElmOrNull(XmlDocument document, String tag) {
    final elements = document.findAllElements(tag);
    return elements.isEmpty ? null : elements.first;
  }

  static XmlElement find(XmlElement element, String tag) {
    return element.findAllElements(tag).first;
  }

  /// 安全查找，不存在时返回 null
  static XmlElement? findOrNull(XmlElement element, String tag) {
    final elements = element.findAllElements(tag);
    return elements.isEmpty ? null : elements.first;
  }

  static Iterable<XmlElement> findElms(XmlDocument document, String tag) {
    return document.findElements(tag);
  }
}

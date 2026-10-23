import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/rss_item.dart';

class ArticleDetail extends StatelessWidget {
  final rss_item item;
  final String sourceName;

  const ArticleDetail({super.key, required this.item, this.sourceName = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(sourceName),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: '在浏览器中打开',
            onPressed: () {
              if (item.link.isNotEmpty) {
                launchUrl(
                  Uri.parse(item.link),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '分享',
            onPressed: () {
              if (item.link.isNotEmpty) {
                launchUrl(Uri.parse(item.link));
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (item.author.isNotEmpty) ...[
                  Icon(Icons.person_outline, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    item.author,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                ],
                if (item.pubDate.isNotEmpty) ...[
                  Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    item.pubDate,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
            const Divider(height: 24),
            HtmlWidget(
              item.description,
              onTapUrl: (url) {
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                return true;
              },
            ),
          ],
        ),
      ),
    );
  }
}

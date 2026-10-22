import 'package:flutter/material.dart';
import 'package:rss_reader/components/DrawerNavigation.dart';
import 'package:http/http.dart' as http;
import 'package:rss_reader/data/rss_root.dart';
import 'package:rss_reader/data/feed_source.dart';
import 'package:xml/xml.dart';

import '../data/rss_item.dart';
import 'ArticleDetail.dart';
import 'FeedManager.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _Home();
}

class _Home extends State<Home> {
  late rss_root rss_feed = rss_root(
    title: "",
    link: "",
    description: "",
    language: "",
    managingEditor: "",
    pubDate: "",
    items: [],
  );

  List<FeedSource> _feedSources = [];
  int _selectedIndex = 0;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initFeedSources();
  }

  Future<void> _initFeedSources() async {
    final sources = await loadFeedSources();
    setState(() {
      _feedSources = sources;
      _selectedIndex = 0;
    });
    if (sources.isNotEmpty) {
      fetchRss(sources.first.url);
    }
  }

  void _onSourceSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    fetchRss(_feedSources[index].url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _feedSources.isNotEmpty
              ? _feedSources[_selectedIndex].name
              : 'QReader',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _loading
                ? null
                : () {
                    if (_feedSources.isNotEmpty) {
                      fetchRss(_feedSources[_selectedIndex].url);
                    }
                  },
          ),
        ],
      ),
      drawer: DrawerNavigation(
        feedSources: _feedSources,
        selectedIndex: _selectedIndex,
        onSourceSelected: _onSourceSelected,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FeedManager()),
          );
          // 从订阅源管理页返回后重新加载订阅源
          final sources = await loadFeedSources();
          setState(() {
            _feedSources = sources;
            if (_selectedIndex >= sources.length) {
              _selectedIndex = 0;
            }
          });
          if (sources.isNotEmpty) {
            fetchRss(sources[_selectedIndex].url);
          }
        },
        icon: const Icon(Icons.rss_feed),
        label: const Text("订阅源管理"),
        elevation: 6,
      ),
      body: _feedSources.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rss_feed, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '暂无订阅源',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击下方按钮添加或导入订阅源',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            )
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: rss_feed.items.length,
                  itemBuilder: (context, index) =>
                      toElement(rss_feed.items[index]),
                ),
    );
  }

  Widget toElement(rss_item item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetail(
                item: item,
                sourceName: _feedSources.isNotEmpty
                    ? _feedSources[_selectedIndex].name
                    : '',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      item.pubDate,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void fetchRss(String url) async {
    setState(() {
      _loading = true;
      rss_feed = rss_root(
        title: "",
        link: "",
        description: "",
        language: "",
        managingEditor: "",
        pubDate: "",
        items: [],
      );
    });
    try {
      final response = await http.get(Uri.parse(url));
      final document = XmlDocument.parse(response.body);
      rss_root root = rss_root.fromXml(document);
      setState(() {
        rss_feed = root;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('获取 RSS 失败：$e')),
        );
      }
    }
  }
}
